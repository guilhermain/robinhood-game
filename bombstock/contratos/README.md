# Contratos do BOMBSTOCK

Escritos e testados em 15/09/2026. **Nada foi deployado em rede pública** — os
testes rodam numa EVM local. O deploy na testnet 46630 depende de uma carteira
com ETH de testnet, e os faucets exigem verificação humana.

## Arquivos

| arquivo | o que é |
|---|---|
| `Tokens.sol` | ERC-20 mínimo. Na testnet vira o $BSTOCK e as sete ações de mentira. Tem torneira aberta para qualquer carteira pegar 1.000 e testar. **Não vai para mainnet**: lá as ações são os contratos reais da Robinhood e o $BSTOCK sai da Pons. |
| `RewardVault.sol` | O cofre. Uma raiz de Merkle por época; o jogador puxa o que é dele provando estar na árvore. |
| `merkle.py` | Monta árvore, raiz e prova compatíveis com o `verificar()` do cofre. |

## Por que Merkle

Com mil jogadores, pagar um a um seriam mil transações por nossa conta. Com
Merkle é **uma transação nossa por época**, e cada jogador paga o próprio gas
quando decide sacar. O contrato nunca empurra pagamento.

## O que os contratos garantem

Testado numa EVM local, cinco jogadores sacando de uma época de verdade, e sete
ataques — todos bloqueados:

- sacar duas vezes a mesma folha
- sacar valor maior que o devido
- usar a prova de outro jogador
- sacar de época que não existe
- publicar época sem ser operador
- republicar uma época já publicada com outra raiz
- recolher o saldo sem ser dono

Contabilidade conferida: 1000 no cofre, 153 sacados, 847 restantes.

## O que os contratos NÃO garantem

**A honestidade do número.** O cofre confere que a folha está na árvore; ele não
tem como saber se a quantidade minerada foi medida corretamente. Hoje quem mede
é o navegador do jogador, que ele controla.

Por isso a regra: **a raiz só pode ser publicada por um servidor autoritativo.**
Enquanto a medição vier do cliente, isto serve para testnet e não para mainnet.

## Custo de deploy medido

| contrato | gas |
|---|---|
| ERC-20 de teste | ~580.000 |
| oito tokens | 4.645.866 |
| RewardVault | 670.293 |

Na testnet, a 0,01 gwei, os oito tokens custam 0,000046 ETH.

## Como deployar quando houver carteira

1. ETH de testnet no endereço de deploy
2. `python3 deploy.py` — compila, envia e grava os endereços
3. apontar `ACAO` no jogo para os endereços de testnet
