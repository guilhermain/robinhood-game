# -*- coding: utf-8 -*-
"""Simulacao da mina no servidor.

A diferenca central para o cliente: o cliente anima 20 vezes por segundo porque
precisa DESENHAR. O servidor nao desenha nada, entao nao precisa de quadro.

Ele avanca por EVENTO: o proximo instante em que algo muda (uma bomba estoura,
um heroi termina de andar, alguem acorda). Entre dois eventos nada acontece, e
pular esse vazio e o que faz mil minas caberem.

Isso importa porque os herois passam ~88% do tempo dormindo. Herois dormindo
custam UM evento cada (a hora de acordar), nao milhares de quadros.
"""
import heapq, random, math, time

LIVRE, PAREDE = 0, 1
BAUS = {'madeira': (80, 1.0), 'pedra': (170, 2.31)}
ROCHAS = {'rocha': 60, 'rocha2': 110, 'rocha3': 170}
PESO = {'rocha':20,'rocha2':16,'rocha3':10,'madeira':28,'pedra':16,'prisao':0.3}
COLS, ROWS = 19, 13

def nova_grade(densidade, rnd):
    g=[[{'t':LIVRE} for _ in range(COLS)] for _ in range(ROWS)]
    for y in range(ROWS):
        for x in range(COLS):
            if x==0 or y==0 or x==COLS-1 or y==ROWS-1 or (x%2==0 and y%2==0):
                g[y][x]={'t':PAREDE}
    tipos=list(PESO); pesos=[PESO[k] for k in tipos]
    for y in range(1,ROWS-1):
        for x in range(1,COLS-1):
            if g[y][x]['t']==PAREDE or rnd.random()>=densidade: continue
            k=rnd.choices(tipos,pesos)[0]
            hp = BAUS[k][0] if k in BAUS else (2000 if k=='prisao' else ROCHAS[k])
            g[y][x]={'t':LIVRE,'b':k,'hp':hp}
    return g

class Mina:
    """Uma mina inteira. Todo o estado cabe aqui e vai para o banco como JSON."""
    __slots__=('grade','herois','fila','agora','achados','limpas','cfg','rnd')
    def __init__(self, herois, cfg, semente):
        self.rnd=random.Random(semente)
        self.cfg=cfg
        self.grade=nova_grade(cfg['densidade'], self.rnd)
        self.agora=0.0
        self.achados=0.0
        self.limpas=0
        self.herois=[]
        self.fila=[]
        for h in herois:
            e=dict(h); e['energia']=h['stamina']*50; e['achados']=0.0
            self.herois.append(e)
            heapq.heappush(self.fila,(0.0,len(self.herois)-1,'agir'))

    def _bau_mais_perto(self):
        alvos=[(x,y) for y in range(1,ROWS-1) for x in range(1,COLS-1)
               if self.grade[y][x].get('b') in BAUS]
        return self.rnd.choice(alvos) if alvos else None

    def avancar(self, ate):
        """Roda ate o instante `ate` (segundos). Devolve quanto foi minerado."""
        ganho=0.0
        while self.fila and self.fila[0][0] <= ate:
            t,i,tipo = heapq.heappop(self.fila)
            self.agora=t
            h=self.herois[i]
            if tipo=='agir':
                if h['energia'] < 1:
                    # dorme ate ter energia: UM evento, nao milhares de quadros
                    falta=(1-h['energia'])
                    espera=falta*self.cfg['regen_ms']/1000.0
                    h['energia']=1
                    heapq.heappush(self.fila,(t+espera,i,'agir'))
                    continue
                alvo=self._bau_mais_perto()
                if not alvo:
                    self.grade=nova_grade(self.cfg['densidade'], self.rnd)
                    self.limpas+=1
                    heapq.heappush(self.fila,(t+1,i,'agir'))
                    continue
                # anda ate o alvo e planta: o tempo sai da velocidade do heroi
                dist=abs(alvo[0]-h.get('gx',1))+abs(alvo[1]-h.get('gy',1))
                h['gx'],h['gy']=alvo
                caminhada=dist*(1.0/max(1,h['speed']))*3
                heapq.heappush(self.fila,(t+caminhada+1.8,i,'estoura'))
                h['_alvo']=alvo
                h['energia']-=1
            else:
                x,y=h.get('_alvo',(1,1))
                c=self.grade[y][x]
                if c.get('b') in BAUS:
                    dano=h['power']+(2 if h.get('hunter') else 0)
                    c['hp']-=dano
                    if c['hp']<=0:
                        paga=BAUS[c['b']][1]
                        ganho+=paga; self.achados+=paga; h['achados']+=paga
                        self.grade[y][x]={'t':LIVRE}
                heapq.heappush(self.fila,(t+0.2,i,'agir'))
        self.agora=ate
        return ganho

    def estado(self):
        return {'grade':self.grade,'herois':self.herois,'agora':self.agora,
                'achados':self.achados,'limpas':self.limpas}
