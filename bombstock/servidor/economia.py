# -*- coding: utf-8 -*-
"""Economia em DOLAR.

As minas sao identicas: mesmo mapa, mesmos baus, mesma dificuldade. Entao o
mesmo esforco vale o mesmo DINHEIRO em qualquer uma; a unica diferenca e qual
acao voce recebe. O bau paga em dolar e o dolar vira quantidade da acao pela
cotacao no momento do saque.

O valor do bau nao e escolhido: ele sai de tres decisoes do G.
  heroi custa US$10 (preco do pacote)
  payback de 30 dias
  heroi medio quebra 17,8 baus/dia no regime estavel (medido em 200h)
=> 10/30 = US$0,333 por dia por heroi / 17,8*1,48 unidades = US$0,0127 o marrom
"""
PAGA = {'madeira': 1.0, 'pedra': 2.31}    # proporcao do Bombcrypto

def valor_bau(cur, tipo):
    cur.execute("select valor from config where chave='usd_bau_marrom'")
    base = float(cur.fetchone()[0])
    return base * PAGA.get(tipo, 1.0)

def config(cur, chave, padrao=None):
    cur.execute("select valor from config where chave=%s", (chave,))
    r = cur.fetchone()
    return float(r[0]) if r else padrao
