import pgserver, psycopg2, os
def conectar():
    uri=os.environ.get('DATABASE_URL')
    if not uri:
        db=pgserver.get_server('/home/claude/pgdata')   # so para teste local
        uri=db.get_uri()
    cn=psycopg2.connect(uri); cn.autocommit=True
    return cn
