# -*- coding: utf-8 -*-
"""BOMBSTOCK — servidor autoritativo.

O que ele conserta: hoje a quantidade minerada nasce no navegador do jogador, e
um contrato de oito linhas drena o cofre. Aqui a conta acontece fora da maquina
de quem ganha.

Regra de arquitetura: NADA de estado em memoria. Cada ciclo le do banco,
calcula e grava. O G publica varias vezes por dia; reiniciar nao pode custar
progresso a ninguem.
"""
import os, json, time, asyncio, contextlib
from datetime import datetime, timezone
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from db import conectar
from auth import novo_desafio, verificar
from economia import valor_bau, config
from sim import Mina

app = FastAPI(title='BOMBSTOCK')
app.add_middleware(CORSMiddleware,
    allow_origins=['https://guilhermain.github.io','http://localhost:8799'],
    allow_credentials=False, allow_methods=['*'], allow_headers=['*'])

CN = None
def cursor():
    global CN
    if CN is None or CN.closed:
        CN = conectar()
    return CN.cursor()

@app.on_event('startup')
def preparar():
    cur = cursor()
    cur.execute(open(os.path.join(os.path.dirname(__file__),'esquema.sql')).read())
    asyncio.get_event_loop().create_task(ciclo())

class Entrada(BaseModel):
    carteira: str
class Prova(BaseModel):
    carteira: str
    assinatura: str

@app.get('/saude')
def saude():
    cur = cursor(); cur.execute('select 1')
    return {'ok': True, 'quando': datetime.now(timezone.utc).isoformat()}

@app.post('/login/desafio')
def desafio(e: Entrada):
    cur = cursor()
    return {'texto': novo_desafio(cur, e.carteira)}

@app.post('/login/verificar')
def login(p: Prova):
    cur = cursor()
    ok, motivo = verificar(cur, p.carteira, p.assinatura)
    cur.execute("insert into evento (carteira,tipo,detalhe) values (%s,%s,%s)",
                (p.carteira.lower(), 'login', json.dumps({'ok': ok, 'motivo': motivo})))
    if not ok:
        raise HTTPException(401, motivo)
    return {'ok': True}

@app.get('/estado/{carteira}')
def estado(carteira: str):
    """O que o cliente desenha. Ele NAO conta mais nada."""
    c = carteira.lower()
    cur = cursor()
    cur.execute("""select tema, achados_usd, limpas, atualizada_em
                   from mina where carteira=%s""", (c,))
    minas = [{'tema': t, 'usd': float(a), 'limpas': l,
              'atualizada_em': q.isoformat()} for t, a, l, q in cur.fetchall()]
    cur.execute("select ticker, usd from saldo_epoca where carteira=%s and epoca=%s",
                (c, epoca_atual(cur)))
    cofre = {t: float(u) for t, u in cur.fetchall()}
    return {'carteira': c, 'minas': minas, 'cofre': cofre,
            'total_usd': round(sum(cofre.values()), 6),
            'min_saque_usd': config(cur, 'min_saque_usd', 10)}

def epoca_atual(cur):
    cur.execute("select coalesce(max(numero),1) from epoca")
    n = cur.fetchone()[0]
    cur.execute("insert into epoca (numero) values (%s) on conflict do nothing", (n,))
    return n

# ---------------------------------------------------------------- o ciclo
CICLO_S = 30

async def ciclo():
    """Avanca todas as minas. Le do banco, calcula, grava. Sem cache."""
    while True:
        try:
            avancar_todas()
        except Exception as e:
            try:
                cur = cursor()
                cur.execute("insert into evento (tipo,detalhe) values ('erro',%s)",
                            (json.dumps({'onde': 'ciclo', 'erro': str(e)[:300]}),))
            except Exception:
                pass
        await asyncio.sleep(CICLO_S)

def avancar_todas():
    cur = cursor()
    agora = datetime.now(timezone.utc)
    cur.execute("""select id, carteira, tema, grade, achados_usd, limpas, atualizada_em
                   from mina""")
    linhas = cur.fetchall()
    if not linhas:
        return
    cfg = {'densidade': config(cur, 'densidade', 0.40),
           'regen_ms': config(cur, 'regen_ms', 120000)}
    base = config(cur, 'usd_bau_marrom', 0.0127)
    ep = epoca_atual(cur)
    for mid, carteira, tema, grade, achados, limpas, quando in linhas:
        segundos = max(0.0, (agora - quando).total_seconds())
        if segundos <= 0:
            continue
        cur.execute("""select token_id, power, stamina, speed, bombas, alcance, skills, energia
                       from heroi where mina_id=%s""", (mid,))
        herois = [{'id': r[0], 'power': r[1], 'stamina': r[2], 'speed': r[3],
                   'bombas': r[4], 'alcance': r[5], 'skills': r[6],
                   'hunter': bool(r[6] & 64)} for r in cur.fetchall()]
        if not herois:
            cur.execute("update mina set atualizada_em=%s where id=%s", (agora, mid))
            continue
        m = Mina(herois, cfg, mid)
        if grade:
            m.grade = grade
        ganho_unidades = m.avancar(segundos)
        ganho_usd = ganho_unidades * base
        ticker = 'USDG' if tema == 'verde' else tema
        cur.execute("""insert into saldo_epoca (epoca,carteira,ticker,usd)
                       values (%s,%s,%s,%s)
                       on conflict (epoca,carteira,ticker)
                       do update set usd = saldo_epoca.usd + excluded.usd""",
                    (ep, carteira, ticker, ganho_usd))
        cur.execute("""update mina set grade=%s, achados_usd=achados_usd+%s,
                       limpas=%s, atualizada_em=%s where id=%s""",
                    (json.dumps(m.grade), ganho_usd, m.limpas, agora, mid))
        for h in m.herois:
            cur.execute("update heroi set energia=%s, achados_usd=achados_usd+%s where token_id=%s",
                        (h['energia'], h['achados'] * base, h['id']))
