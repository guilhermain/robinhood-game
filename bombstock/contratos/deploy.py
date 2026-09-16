#!/usr/bin/env python3
"""Deploy dos contratos do BOMBSTOCK na Robinhood Chain testnet (46630).

Uso:  CHAVE=0x... python3 deploy.py
A chave sai do ambiente e nunca fica no repositorio.
"""
import json, os, sys
import solcx
from web3 import Web3
from eth_account import Account

RPC='https://rpc.testnet.chain.robinhood.com'
EXPLORER='https://explorer.testnet.chain.robinhood.com'
AQUI=os.path.dirname(os.path.abspath(__file__))

ACOES=[('BOMBSTOCK','BSTOCK',1_000_000_000),('Test NVDA','NVDA',0),('Test GME','GME',0),
       ('Test AMZN','AMZN',0),('Test MSTR','MSTR',0),('Test META','META',0),
       ('Test SPCX','SPCX',0),('Test USDG','USDG',0)]

def compilar():
    solcx.set_solc_version('0.8.24')
    out=solcx.compile_files([f'{AQUI}/Tokens.sol', f'{AQUI}/RewardVault.sol'],
        output_values=['abi','bin'], optimize=True, optimize_runs=200)
    pega=lambda n: out[[k for k in out if k.endswith(':'+n)][0]]
    return pega('TokenTeste'), pega('RewardVault')

def enviar(w, conta, tx):
    tx['nonce']=w.eth.get_transaction_count(conta.address)
    tx['chainId']=w.eth.chain_id
    tx.setdefault('gasPrice', w.eth.gas_price)
    tx.setdefault('gas', 3_000_000)
    assinada=conta.sign_transaction(tx)
    h=w.eth.send_raw_transaction(assinada.raw_transaction)
    return w.eth.wait_for_transaction_receipt(h, timeout=180)

def main():
    chave=os.environ.get('CHAVE')
    if not chave: sys.exit('faltou CHAVE no ambiente')
    conta=Account.from_key(chave)
    w=Web3(Web3.HTTPProvider(RPC))
    if not w.is_connected(): sys.exit('sem conexao com a testnet')
    saldo=w.eth.get_balance(conta.address)
    print(f'conta {conta.address} | saldo {w.from_wei(saldo,"ether")} ETH | chain {w.eth.chain_id}')
    if saldo==0: sys.exit('sem ETH de testnet: use um faucet antes')

    tokArt, cofArt = compilar()
    T=w.eth.contract(abi=tokArt['abi'], bytecode=tokArt['bin'])
    enderecos={}
    for nome,simb,inicial in ACOES:
        tx=T.constructor(nome,simb,w.to_wei(inicial,'ether')).build_transaction({'from':conta.address})
        r=enviar(w, conta, tx)
        enderecos[simb]=r.contractAddress
        print(f'  {simb:7} {r.contractAddress}  gas {r.gasUsed:,}')

    C=w.eth.contract(abi=cofArt['abi'], bytecode=cofArt['bin'])
    tx=C.constructor(conta.address).build_transaction({'from':conta.address})
    r=enviar(w, conta, tx)
    enderecos['VAULT']=r.contractAddress
    print(f'  {"VAULT":7} {r.contractAddress}  gas {r.gasUsed:,}')

    json.dump({'chainId':w.eth.chain_id,'explorer':EXPLORER,'enderecos':enderecos},
              open(f'{AQUI}/enderecos_testnet.json','w'), indent=1)
    print('\ngravado em enderecos_testnet.json')
    for s,a in enderecos.items(): print(f'  {EXPLORER}/address/{a}')

if __name__=='__main__': main()
