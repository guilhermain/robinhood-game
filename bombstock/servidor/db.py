# -*- coding: utf-8 -*-
"""Conexao com o banco.

Em producao usa DATABASE_URL. Sem ela, sobe um Postgres embutido — util para
testar aqui, e por isso o import do pgserver e PREGUICOSO: em producao esse
pacote nao existe, e importar no topo derrubava o servidor inteiro no arranque.
"""
import os, psycopg2

def conectar():
    uri = os.environ.get('DATABASE_URL')
    if not uri:
        import pgserver                      # so no ambiente de teste
        uri = pgserver.get_server('/home/claude/pgdata').get_uri()
    cn = psycopg2.connect(uri)
    cn.autocommit = True
    return cn
