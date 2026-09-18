# -*- coding: utf-8 -*-
"""Keeper: fecha a epoca e publica a raiz na chain.

Sem ele o jogador minera e nunca tem o que sacar — fechar e publicar eram feitos
a mao. Roda dentro do proprio servidor, num laco, e nao precisa de maquina nova.

Duas regras aprendidas errando:

1. O NUMERO DA EPOCA E DO CONTRATO. O numero entra na folha de Merkle, entao
   servidor e contrato precisam concordar. Publicar a epoca 2 do servidor numa
   epoca 2 do contrato com outra raiz da ProvaInvalida — foi o que aconteceu.
   O keeper le epocaAtual() do contrato e trabalha a partir dela.

2. FECHAR ANTES DE PUBLICAR. Fechar congela o dolar e a cotacao; sem isso a
   raiz muda depois de publicada e as provas emitidas nascem invalidas.
"""
import os, time, json, threading
import httpx
from eth_account import Account
from eth_abi import encode
from eth_utils import keccak

RPC        = os.environ.get('CHAIN_RPC', 'https://rpc.testnet.chain.robinhood.com')
CHAIN_ID   = int(os.environ.get('CHAIN_ID', '46630'))
VAULT      = os.environ.get('VAULT_ADDR', '0x62eea8D4bBbC92b08333695Fce6580df21B9dD04')
CHAVE      = os.environ.get('KEEPER_PK', '')          # sem ela o keeper nao roda
HORAS      = float(os.environ.get('EPOCA_HORAS', '24'))
INTERVALO  = 300                                       # olha a cada 5 min

SEL_PUBLICAR = keccak(text='publicarEpoca(uint256,bytes32)')[:4].hex()
SEL_ATUAL    = keccak(text='epocaAtual()')[:4].hex()
SEL_EPOCAS   = keccak(text='epocas(uint256)')[:4].hex()

def _rpc(metodo, params):
    r = httpx.post(RPC, json={'jsonrpc':'2.0','id':1,'method':metodo,'params':params}, timeout=30)
    j = r.json()
    if 'error' in j:
        raise RuntimeError(j['error'].get('message','rpc'))
    return j['result']

def epoca_do_contrato():
    return int(_rpc('eth_call', [{'to': VAULT, 'data': '0x'+SEL_ATUAL}, 'latest']), 16)

def ja_publicada(n):
    d = _rpc('eth_call', [{'to': VAULT,
        'data': '0x'+SEL_EPOCAS+format(n,'064x')}, 'latest'])[2:]
    # (raiz, publicadaEm, existe) -> o terceiro campo
    return int(d[128:192], 16) == 1 if len(d) >= 192 else False

def publicar(n, raiz_hex):
    conta = Account.from_key(CHAVE)
    dados = '0x'+SEL_PUBLICAR+format(n,'064x')+raiz_hex[2:]
    nonce = int(_rpc('eth_getTransactionCount', [conta.address, 'pending']), 16)
    preco = int(_rpc('eth_gasPrice', []), 16)
    tx = {'to': VAULT, 'data': dados, 'gas': 300000, 'gasPrice': preco,
          'nonce': nonce, 'chainId': CHAIN_ID, 'value': 0}
    assinada = conta.sign_transaction(tx)
    h = _rpc('eth_sendRawTransaction', ['0x'+assinada.raw_transaction.hex()])
    for _ in range(60):
        time.sleep(2)
        r = _rpc('eth_getTransactionReceipt', [h])
        if r:
            return h, r['status'] == '0x1'
    return h, None

def ciclo_keeper(cursor_fn, fechar_fn, previa_fn, config_fn):
    """Laco principal. Recebe funcoes do app para nao duplicar acesso ao banco."""
    if not CHAVE:
        return
    while True:
        try:
            cur = cursor_fn()
            # a epoca do servidor acompanha a do contrato
            alvo = epoca_do_contrato() + 1
            cur.execute("select numero, aberta_em, fechada_em, raiz, publicada_em "
                        "from epoca order by numero")
            linhas = {r[0]: r for r in cur.fetchall()}

            # 1. abre a epoca alvo se ela nao existe
            if alvo not in linhas:
                cur.execute("insert into epoca (numero) values (%s) on conflict do nothing", (alvo,))
                cur.execute("update epoca set fechada_em=coalesce(fechada_em, now()) "
                            "where numero < %s and fechada_em is null", (alvo,))
                time.sleep(INTERVALO); continue

            n, aberta, fechada, raiz, publicada = linhas[alvo]

            # 2. hora de fechar?
            if not fechada:
                cur.execute("select extract(epoch from (now()-%s))/3600", (aberta,))
                horas = float(cur.fetchone()[0])
                if horas >= HORAS:
                    fechar_fn(n)
                time.sleep(INTERVALO); continue

            # 3. fechada e com raiz: publica
            if raiz and not publicada and not ja_publicada(n):
                h, ok = publicar(n, raiz)
                cur.execute("update epoca set publicada_em=now() where numero=%s", (n,))
                cur.execute("insert into evento (tipo,detalhe) values ('epoca_publicada',%s)",
                            (json.dumps({'epoca': n, 'tx': h, 'ok': ok, 'raiz': raiz}),))
        except Exception as e:
            try:
                cur = cursor_fn()
                cur.execute("insert into evento (tipo,detalhe) values ('erro',%s)",
                            (json.dumps({'onde': 'keeper', 'erro': str(e)[:300]}),))
            except Exception:
                pass
        time.sleep(INTERVALO)

def iniciar(cursor_fn, fechar_fn, previa_fn, config_fn):
    if not CHAVE:
        return False
    t = threading.Thread(target=ciclo_keeper, daemon=True,
                         args=(cursor_fn, fechar_fn, previa_fn, config_fn))
    t.start()
    return True
