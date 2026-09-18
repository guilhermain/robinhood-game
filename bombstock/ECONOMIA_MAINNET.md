# BOMBSTOCK — o ciclo do dinheiro na mainnet

Escrito em 18/09/2026. Descreve o estágio final, com a Pons no meio. Substitui
qualquer desenho que tratasse o `CofreTeste` como protótipo: ele é andaime da
testnet e **nenhuma das funções dele sobrevive**.

## O que é nosso e o que não é

| peça | quem opera |
|---|---|
| $BSTOCK: lançamento, curva, liquidez, taxa | **Pons** |
| As sete ações tokenizadas | **Robinhood** |
| Pool BSTOCK/USDG | **Pons** (liquidez travada na graduação) |
| NFT do herói | nosso |
| RewardVault (Merkle) | nosso |
| Servidor e keeper | nosso |

Só duas peças de contrato são nossas. Tudo o mais é infraestrutura de terceiros,
e é isso que reduz a superfície de ataque do projeto.

## O ciclo, do trade ao jogador

**1. Alguém negocia $BSTOCK.** Cada trade paga 1% de taxa padrão na Pons. O
protocolo fica com 30%; o restante vai para o criador e para o buyback. Além
disso o criador pode cobrar um imposto próprio, até 10% — o nosso é 3%.

**2. A Pons acumula em escrow.** A taxa NÃO cai na carteira: ela se acumula num
contrato de escrow e o criador **saca quando quiser**, no ativo do par. Como o
par é USDG, a taxa chega em **USDG**.

Isto tem uma consequência de desenho: o dinheiro do jogo entra em dólar, não em
ETH nem em $BSTOCK. Não há conversão a fazer na entrada.

**3. O keeper saca o escrow.** Só a carteira criadora pode sacar. Na mainnet
essa carteira é o **Safe (multisig)**, não uma chave solta — é o item 1 do
`MAINNET.md` e é por isso que ele bloqueia o lançamento: **quem controla a
carteira criadora controla toda a receita do jogo**.

**4. O Safe distribui,** pelo que o G decidiu:
- **60%** compra as sete ações na Robinhood e deposita no `RewardVault`
- **20%** time
- **10%** queima de $BSTOCK (comprado no pool)
- **10%** reserva

**5. O servidor fecha a época.** Congela dólar e cotação, monta a árvore de
Merkle, o keeper publica a raiz no `RewardVault`.

**6. O jogador saca** apresentando a prova. Paga o próprio gas. O contrato só
paga quem está na árvore.

## Onde cada risco mora agora

| risco | onde | quem resolve |
|---|---|---|
| Liquidez sumir | pool travado na graduação | Pons, por contrato |
| Taxa desviada | escrow da Pons, saque só pela carteira criadora | **Safe** |
| Cofre drenado | `RewardVault` exige prova de Merkle | nosso, já testado |
| Mint manipulado | commit-reveal | nosso, pendente |
| Raiz falsa publicada | quem publica é o keeper | **Safe** + teto por época |

Repare que **três dos cinco dependem do Safe**. Não é burocracia: é o ponto
único onde o dinheiro do projeto pode ser perdido de uma vez.

## O que isto muda no plano

- O `CofreTeste` não precisa ser consertado nem substituído: some.
- Não existe "contrato de compra de mina" a escrever. A compra de mina gasta
  $BSTOCK, e $BSTOCK é da Pons — o gasto vira transferência para o Safe, ou é
  queimado, conforme o G decidir. **Decisão pendente.**
- A entrada do jogo é em USDG. O `usd_bau_marrom` já está em dólar, então a
  economia do servidor não muda.

## Pendências desta página
1. O que acontece com o $BSTOCK gasto dentro do jogo (pacotes, minas): vai para
   o Safe, é queimado, ou volta ao cofre? **G decide.**
2. Com que frequência o keeper saca o escrow da Pons.
3. Se a compra de ações na Robinhood é manual (o G comprando) ou automática.
