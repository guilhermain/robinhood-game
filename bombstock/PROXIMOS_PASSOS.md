# BOMBSTOCK — próximos passos

Atualizado em 16/09/2026, depois do deploy na testnet.
Fonte de verdade do que falta. Leia `PLANO.md` e `DECISOES.md` em seguida.

## Onde as coisas estão

| | endereço |
|---|---|
| Site | https://guilhermain.github.io/robinhood-game/bombstock/ |
| Jogo | https://guilhermain.github.io/robinhood-game/bombstock/play/ |
| Fonte | repo `guilhermain/robinhood-game`, pasta `bombstock/` |

## Contratos na testnet 46630

Deployados e testados em 16/09. RPC `https://rpc.testnet.chain.robinhood.com`,
explorer `https://explorer.testnet.chain.robinhood.com`.

| contrato | endereço |
|---|---|
| $BSTOCK | `0x96E24ea635d9aD490C37081Ff4B3bF4dFBBF3463` |
| Herói (NFT) | `0x9BefA801E9A09aCDE1dFf3B78dF0c99dAaF6F65c` |
| CofreTeste | `0x97A54706195aDa31247e650c1dD7d94efcb594C1` |
| RewardVault (Merkle) | `0x62eea8D4bBbC92b08333695Fce6580df21B9dD04` |
| NVDA | `0xDC45135193Cb5D39cEB11Fa1A7ACA94EEF354c29` |
| GME | `0x845600899De5fA4CEf16d8CEAbeb30A5fc780EDB` |
| AMZN | `0x7BdBb4C9a3481bb6171D90FAB1f836C721A65151` |
| MSTR | `0x09939e5aE89c0e22381258F7A63165aeE738Da8d` |
| META | `0x0517b9166aDdF1A0c5E9499CCF092b27e3F490DB` |
| SPCX | `0xeF77540f7cCC487c28C67811F3A45E1D1c2fc020` |
| USDG | `0x19cE998F1d1b0Bb0A85657a08003503E7374213b` |

Carteira de deploy: `0x0003c19b0e0777AFbD723E8c523bb9c3411bB172`, com ~0,09 ETH
de testnet. **Chave gerada dentro do container — tratar como comprometida**,
serve só para testnet.

## O que já funciona on-chain

- Conectar carteira, trocar/adicionar a rede 46630
- Carteira nova recebe $BSTOCK de teste pela torneira, dentro do jogo
- **Comprar pacote gasta $BSTOCK de verdade e minta NFT**, com raridade, stats e
  skills sorteados DENTRO do contrato
- O jogo lê o inventário do contrato em vez de sortear no navegador
- Sacar transfere token do cofre para a carteira
- Preço das sete ações lido ao vivo (da mainnet: o token de testnet não tem mercado)

## Os três furos, e o estado de cada um

1. **Carteira nova sem $BSTOCK** — RESOLVIDO (torneira no jogo)
2. **Raridade sorteada no navegador** — RESOLVIDO (sorteio no contrato)
3. **Quantidade minerada nasce no navegador** — SEM CONSERTO sem servidor.
   O cofre de testnet paga sem checar nada, de propósito. É o bloqueio de
   sempre e o motivo de nada disso poder ir para a mainnet.

## Próximos passos, em ordem

### 1. Exigir carteira (pedido do G em 16/09, adiado)
Hoje o jogo roda sem carteira e entrega herói de graça — ou seja, o caminho
on-chain é opcional e ninguém vai usar. Quando ligar: sem carteira, sem jogo.
Custo: quem não tiver carteira para de conseguir testar, inclusive a amiga do G.
O inventário de demonstração (18 heróis com 10 Elon) sai junto.

### 2. Aleatoriedade decente
O seed hoje vem de blockhash e timestamp. Com sequenciador único, quem opera o
sequenciador influencia. Para mainnet: commit-reveal com assinatura de servidor
entrando no seed. O `HeroNFT_v2.sol` faz isso, mas tem 5 raridades e o jogo tem
6 — precisa ser adaptado antes de usar.

### 3. Servidor autoritativo
Desbloqueia tudo o que paga. Simulação no servidor, login por assinatura, banco,
fechamento de época, raiz de Merkle publicada por quem tem autoridade. Só depois
disso o `RewardVault` substitui o `CofreTeste` e a mainnet entra na conversa.

### 4. Comprar mina on-chain
Já existe no contrato (`comprarMina`), mas o jogo ainda não usa o retorno para
liberar a mina — hoje a liberação é local.

## Pendente de decisão do G

1. **Preço de entrada.** Pacote de 1 está em 10 $BSTOCK no contrato, número
   herdado do jogo local. Ancorar em dólar evita a espiral que matou o
   Bombcrypto: token cai, pacote fica barato, produção explode, token cai mais.
2. **Taxa de conversão share → ação (`FRACAO`).** Está `null` no código e a tela
   mostra `$—`. Com o cofre real ela se calcula sozinha: ação no cofre dividido
   pelas shares da época. Enquanto não existir, não há valor em dólar para
   mostrar.
3. **Identidade visual.** Site é roxo com Inter; jogo é âmbar com Archivo.
4. **Mínimo de saque.** Baixado de 40 para 10 shares.
5. **O terceiro baú** (800 de vida) está desligado: as folhas por mina vieram com
   dois tipos só.
6. **Rocha própria da Green Field** — é a única sem rocha temática.
7. **Travar as minas de novo** quando quiser lançar aos poucos: trocar
   `VENDA_DE_MINA` para `false`.
8. **Devolver 0,001 ETH** que está na Robinhood MAINNET (dinheiro real) —
   falta o G dizer o destino. Os 0,002 da Ethereum já foram devolvidos em
   `0x7b88eb4a547b3116ae28324ad1b0d404129d8e275f8813dc642a8b26f3366cf2`.

## Decidido, não reabrir

- **Sem bônus na conversão** para $BSTOCK: converter paga o mesmo que receber a
  ação (G, 15/09).
- **Seis raridades**, a escala do Bombcrypto. O site se ajusta ao jogo (G, 16/09).
- **A Green Field espalha as sete ações**; as pagas concentram na própria.
- **Mineração não roda on-chain** — seriam centenas de transações por hora por
  jogador. Nenhum jogo do gênero faz isso.

## Dívidas técnicas

- Dois arneses de simulação dão números absolutos incompatíveis (800 moedas/h
  contra 30 na mesma configuração). Só comparação dentro da mesma rodada é
  confiável.
- Inventário de demonstração e saldo inicial de 200 estão marcados no código.
- `CofreTeste.sol` tem saque livre e **não pode ir para a mainnet** — está
  escrito no topo do arquivo.
