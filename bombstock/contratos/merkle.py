"""Arvore de Merkle compativel com o verificar() do RewardVault:
   folha = keccak(keccak(abi.encode(epoca, jogador, token, valor)))
   no    = keccak(abi.encode(menor, maior))"""
from eth_abi import encode
from eth_utils import keccak

def folha(epoca, jogador, token, valor):
    return keccak(keccak(encode(['uint256','address','address','uint256'],
                                [epoca, jogador, token, valor])))

def _par(a, b):
    return keccak(encode(['bytes32','bytes32'], [a, b] if a <= b else [b, a]))

def arvore(folhas):
    niveis=[list(folhas)]
    while len(niveis[-1]) > 1:
        atual=niveis[-1]; acima=[]
        for i in range(0, len(atual), 2):
            acima.append(_par(atual[i], atual[i+1]) if i+1 < len(atual) else atual[i])
        niveis.append(acima)
    return niveis

def raiz(folhas):
    return arvore(folhas)[-1][0]

def prova(folhas, i):
    niveis=arvore(folhas); p=[]
    for nivel in niveis[:-1]:
        irmao = i ^ 1
        if irmao < len(nivel): p.append(nivel[irmao])
        i //= 2
    return p
