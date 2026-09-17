# -*- coding: utf-8 -*-
"""Login por assinatura de carteira (SIWE simplificado).

Por que assim: o servidor precisa saber de quem e a mina sem senha, sem e-mail
e sem guardar nada que possa vazar. A carteira prova quem e assinando um texto
que o servidor sorteou.

Tres regras que impedem os ataques obvios:
  1. O desafio e sorteado pelo SERVIDOR e guardado no banco. Se o cliente
     escolhesse o texto, ele poderia mandar assinar qualquer coisa.
  2. O desafio VENCE em minutos e e QUEIMADO no uso. Sem isso, uma assinatura
     capturada uma vez serviria para sempre.
  3. O texto diz o dominio e a carteira. Assim uma assinatura feita para outro
     site nao vale aqui.
"""
import secrets, time
from datetime import datetime, timedelta, timezone
from eth_account import Account
from eth_account.messages import encode_defunct

DOMINIO = 'bombstock.game'
VALIDADE_MIN = 5

def texto_do_desafio(carteira, nonce, quando):
    return (f"{DOMINIO} quer verificar sua carteira.\n\n"
            f"Carteira: {carteira}\n"
            f"Codigo: {nonce}\n"
            f"Emitido: {quando.isoformat()}\n\n"
            f"Assinar nao custa gas e nao autoriza nenhuma transacao.")

def novo_desafio(cur, carteira):
    carteira = carteira.lower()
    nonce = secrets.token_hex(16)
    agora = datetime.now(timezone.utc)
    expira = agora + timedelta(minutes=VALIDADE_MIN)
    texto = texto_do_desafio(carteira, nonce, agora)
    # guarda o TEXTO, nao as pecas: reconstruir depois erra nos microssegundos
    cur.execute("""insert into jogador (carteira, desafio, desafio_expira)
                   values (%s,%s,%s)
                   on conflict (carteira) do update
                     set desafio=excluded.desafio, desafio_expira=excluded.desafio_expira""",
                (carteira, texto, expira))
    return texto

def verificar(cur, carteira, assinatura):
    """Devolve (ok, motivo). Nunca levanta excecao para entrada malformada."""
    carteira = (carteira or '').lower()
    cur.execute("select desafio, desafio_expira from jogador where carteira=%s", (carteira,))
    linha = cur.fetchone()
    if not linha or not linha[0]:
        return False, 'sem desafio aberto'
    texto, expira = linha
    if expira is None or datetime.now(timezone.utc) > expira:
        return False, 'desafio expirado'
    try:
        recuperada = Account.recover_message(encode_defunct(text=texto), signature=assinatura)
    except Exception:
        return False, 'assinatura invalida'
    if recuperada.lower() != carteira:
        return False, 'assinatura nao confere com a carteira'
    # queima o desafio: uma assinatura, um uso
    cur.execute("update jogador set desafio=null, desafio_expira=null, visto_em=now() where carteira=%s",
                (carteira,))
    return True, 'ok'
