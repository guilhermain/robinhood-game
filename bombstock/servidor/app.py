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
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

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

import httpx

RPC = os.environ.get('CHAIN_RPC', 'https://rpc.testnet.chain.robinhood.com')
HEROI_ADDR = os.environ.get('HEROI_ADDR', '0x6f95BC604aD54c759b03856B783050d9967E2d8c')

def _rpc(metodo, params):
    r = httpx.post(RPC, json={'jsonrpc':'2.0','id':1,'method':metodo,'params':params}, timeout=20)
    j = r.json()
    if 'error' in j: raise RuntimeError(j['error'].get('message','rpc'))
    return j['result']

def _pad(v):  return format(int(v), '064x')
def _padA(a): return a.lower().replace('0x','').rjust(64,'0')

def herois_da_chain(carteira):
    """A chain e dona do inventario. O servidor le, nao inventa."""
    dados = _rpc('eth_call', [{'to': HEROI_ADDR, 'data': '0x'+SEL_LISTA+_padA(carteira)}, 'latest'])[2:]
    n = int(dados[64:128], 16)
    saida = []
    for i in range(n):
        tid = int(dados[128+i*64 : 192+i*64], 16)
        d = _rpc('eth_call', [{'to': HEROI_ADDR, 'data': '0x'+SEL_HEROI+_pad(tid)}, 'latest'])[2:]
        c = [int(d[j*64:(j+1)*64], 16) for j in range(8)]
        saida.append({'token_id':tid, 'raridade':c[0], 'personagem':c[1], 'power':c[2],
                      'stamina':c[3], 'speed':c[4], 'bombas':c[5], 'alcance':c[6], 'skills':c[7]})
    return saida

SEL_LISTA = '1f08a921'   # heroisDe(address)
SEL_HEROI = 'bd776cb2'   # herois(uint256)

class Entrada(BaseModel):
    carteira: str
class Prova(BaseModel):
    carteira: str
    assinatura: str

from collections import defaultdict, deque
_batidas = defaultdict(deque)
def limitar(chave, maximo, janela_s):
    """Limite simples em memoria. Nao e perfeito (reinicia no deploy), mas
    impede o martelo obvio: 60 pedidos em 10s passavam sem nada."""
    agora = time.time()
    d = _batidas[chave]
    while d and agora - d[0] > janela_s:
        d.popleft()
    if len(d) >= maximo:
        raise HTTPException(429, 'devagar')
    d.append(agora)
    if len(_batidas) > 20000:
        _batidas.clear()

@app.get('/saude')
def saude():
    cur = cursor(); cur.execute('select 1')
    return {'ok': True, 'quando': datetime.now(timezone.utc).isoformat()}

@app.post('/login/desafio')
def desafio(e: Entrada, request: Request):
    # Cada desafio cria linha no banco SEM prova nenhuma: 12 carteiras novas
    # entraram em 1,9s no teste. O limite e por origem, nao por carteira,
    # porque a carteira e de graca.
    limitar('desafio:'+(request.client.host if request.client else '?'), 20, 60)
    cur = cursor()
    return {'texto': novo_desafio(cur, e.carteira)}

import hashlib, secrets as _sec
from fastapi import Header
from datetime import timedelta

SESSAO_HORAS = 24

def _hash(t): return hashlib.sha256(t.encode()).hexdigest()

@app.post('/login/verificar')
def login(p: Prova):
    cur = cursor()
    ok, motivo = verificar(cur, p.carteira, p.assinatura)
    cur.execute("insert into evento (carteira,tipo,detalhe) values (%s,%s,%s)",
                (p.carteira.lower(), 'login', json.dumps({'ok': ok, 'motivo': motivo})))
    if not ok:
        raise HTTPException(401, motivo)
    # Emite a sessao. Sem isto, o login verificava quem voce e e depois
    # esquecia: qualquer um chamava /mina/entrar em nome de qualquer carteira.
    token = _sec.token_urlsafe(32)
    cur.execute("update jogador set sessao_hash=%s, sessao_expira=%s where carteira=%s",
                (_hash(token), datetime.now(timezone.utc)+timedelta(hours=SESSAO_HORAS),
                 p.carteira.lower()))
    return {'ok': True, 'token': token, 'expira_h': SESSAO_HORAS}

def exigir_sessao(carteira: str, authorization: str):
    """Toda acao passa por aqui. Token errado, vencido ou de outra carteira: 401."""
    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(401, 'sem sessao')
    token = authorization[7:].strip()
    cur = cursor()
    cur.execute("select sessao_hash, sessao_expira from jogador where carteira=%s",
                (carteira.lower(),))
    r = cur.fetchone()
    if not r or not r[0] or r[0] != _hash(token):
        raise HTTPException(401, 'sessao invalida')
    if r[1] is None or datetime.now(timezone.utc) > r[1]:
        raise HTTPException(401, 'sessao expirada')

@app.post('/logout')
def logout(e: Entrada, authorization: str = Header(default='')):
    exigir_sessao(e.carteira, authorization)
    cur = cursor()
    cur.execute("update jogador set sessao_hash=null, sessao_expira=null where carteira=%s",
                (e.carteira.lower(),))
    return {'ok': True}

# Só estes temas existem. Sem a lista, qualquer texto virava uma mina nova no
# banco: testado, "GOOGL_FALSO" e um tema de 500 letras foram aceitos.
TEMAS = {'verde','NVDA','GME','AMZN','MSTR','META','SPCX'}

class Descer(BaseModel):
    carteira: str
    tema: str
    tokens: list[int] = Field(default_factory=list, max_length=64)

@app.post('/mina/entrar')
def entrar_na_mina(d: Descer, authorization: str = Header(default='')):
    """O jogador escolhe a mina e quem desce. O servidor confere na CHAIN que os
    herois sao dele, e a SESSAO prova que quem pede e o dono da carteira."""
    exigir_sessao(d.carteira, authorization)
    limitar('entrar:'+d.carteira.lower(), 10, 60)
    if d.tema not in TEMAS:
        raise HTTPException(400, 'tema desconhecido')
    c = d.carteira.lower()
    cur = cursor()
    # Uma mina por vez: sem isto, quatro pedidos ao mesmo tempo criavam quatro
    # minas para a mesma carteira. Os herois ficavam em uma so, mas as outras
    # persistiam no banco. O lock serializa a carteira.
    cur.execute("select pg_advisory_xact_lock(hashtext(%s))", (c,))
    try:
        meus = {h['token_id']: h for h in herois_da_chain(c)}
    except Exception as e:
        raise HTTPException(502, 'nao consegui ler a chain: ' + str(e)[:120])
    pedidos = [t for t in d.tokens if t in meus]
    if not pedidos:
        raise HTTPException(400, 'nenhum desses herois e seu')
    vagas = int(config(cur, 'vagas', 10))
    pedidos = pedidos[:vagas]

    cur.execute("insert into jogador (carteira) values (%s) on conflict do nothing", (c,))
    cur.execute("insert into mina (carteira, tema, atualizada_em) values (%s,%s,now()) "
                "on conflict (carteira, tema) do update set atualizada_em=mina.atualizada_em "
                "returning id", (c, d.tema))
    mid = cur.fetchone()[0]
    cur.execute("update heroi set mina_id=null where carteira=%s", (c,))
    for t in pedidos:
        h = meus[t]
        cur.execute(
            "insert into heroi (token_id,carteira,raridade,personagem,power,stamina,"
            "speed,bombas,alcance,skills,energia,mina_id) "
            "values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s) "
            "on conflict (token_id) do update set "
            "carteira=excluded.carteira, mina_id=excluded.mina_id",
            (t, c, h['raridade'], h['personagem'], h['power'], h['stamina'],
             h['speed'], h['bombas'], h['alcance'], h['skills'], h['stamina']*50, mid))
    cur.execute("insert into evento (carteira,tipo,detalhe) values (%s,'descer',%s)",
                (c, json.dumps({'tema': d.tema, 'herois': pedidos})))
    return {'ok': True, 'mina': mid, 'herois': len(pedidos)}


@app.get('/estado/{carteira}')
def estado(carteira: str, request: Request):
    limitar('estado:'+(request.client.host if request.client else '?'), 60, 60)
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
