# BOMBSTOCK — próximos passos

Atualizado em 17/09/2026. Fonte de verdade do que falta.
Leia também `SEGURANCA.md` (auditoria com ataques executados) e `DECISOES.md`.

## Onde as coisas estão

| | endereço |
|---|---|
| Site | https://guilhermain.github.io/robinhood-game/bombstock/ |
| Jogo | https://guilhermain.github.io/robinhood-game/bombstock/play/ |
| **Servidor** | https://robinhood-game-production-3577.up.railway.app |
| Fonte | repo `guilhermain/robinhood-game`, pasta `bombstock/` |

Railway: projeto `bombstock`, Postgres com volume, deploy automático a cada
commit em `bombstock/servidor/**`. Publicar o jogo **não** reconstrói o servidor.

## Contratos na testnet 46630

| contrato | endereço |
|---|---|
| $BSTOCK | `0x96E24ea635d9aD490C37081Ff4B3bF4dFBBF3463` |
| Herói (NFT, sem garantia de raridade) | `0x6f95BC604aD54c759b03856B783050d9967E2d8c` |
| CofreTeste (lote + conversão) | `0x4C393939B35D9c7C58bb955b277ffF0C52C77f21` |
| MiniPool BSTOCK/USDG | `0xA856Bf43eB7C0c522AF2B4bE31A529bdf724dCC5` |
| RewardVault (Merkle, não usado ainda) | `0x62eea8D4bBbC92b08333695Fce6580df21B9dD04` |
| NVDA | `0xDC45135193Cb5D39cEB11Fa1A7ACA94EEF354c29` |
| GME | `0x845600899De5fA4CEf16d8CEAbeb30A5fc780EDB` |
| AMZN | `0x7BdBb4C9a3481bb6171D90FAB1f836C721A65151` |
| MSTR | `0x09939e5aE89c0e22381258F7A63165aeE738Da8d` |
| META | `0x0517b9166aDdF1A0c5E9499CCF092b27e3F490DB` |
| SPCX | `0xeF77540f7cCC487c28C67811F3A45E1D1c2fc020` |
| USDG | `0x19cE998F1d1b0Bb0A85657a08003503E7374213b` |

Carteira de deploy `0x0003c19b0e0777AFbD723E8c523bb9c3411bB172`, ~0,098 ETH de
testnet. **Chave gerada no container: tratar como comprometida.**

## Já funciona

**On-chain:** conectar e desconectar, trocar de rede, torneira de $BSTOCK,
comprar pacote mintando NFT com raridade sorteada no contrato, comprar mina,
sacar as sete ações em UMA transação, converter em $BSTOCK com buyback real no
pool (o preço sobe conforme se compra), ler preço, cofre, saldo e inventário.

**Servidor:** no ar, login por assinatura com sete ataques bloqueados, simulação
da mina por evento, economia em dólar, estado do banco. Medido: mil minas custam
**6,5% de um núcleo** e 56 MB.

**Economia:** payback de 30 dias confirmado no servidor em 240h de simulação.

## Fase A — o que já fechou

- [x] **Servidor conta a mineração.** Com sessão, quebrar baú pelo console não
      credita nada (testado: 16 baús, saldo inalterado).
- [x] **Sessão com token.** Antes qualquer um agia em nome de qualquer carteira.
- [x] **Fechamento de época com Merkle.** Servidor congela dólar e cotação,
      monta a árvore, publica a raiz. O jogador saca com prova.
- [x] **Keeper.** Fecha e publica sozinho, alinhado com `epocaAtual()` do
      contrato. Confirmado em produção: fechou a época 5 e publicou a raiz na
      tx `0x7840fa0e82b8d483ac7d0c40c65899796f6021a662bc4921f7cf7bd8de3085e8`;
      a raiz na chain bate com a do servidor e o saque com prova pagou
      0,01142069 NVDA.

## Falta na fase A

### Multisig — depende do G
Uma chave é dona de todos os contratos, é o operador do cofre **e agora assina
como keeper**. Ela foi gerada no container: trate como comprometida. Na mainnet
isso não pode existir.

### Exigir carteira
Enquanto o caminho local existir, o `CofreTeste` — que paga o que pedirem —
continua no código.

### Antigo próximo passo (feito)

### Ligar o cliente ao servidor
É o que fecha o ataque nº 1 do `SEGURANCA.md`: hoje a quantidade minerada nasce
no navegador, e um contrato de oito linhas drena o cofre (**provado: 20.000 NVDA
numa transação**).

Ordem:
1. Cliente faz login por assinatura e guarda a sessão.
2. Cliente **para de contar**: o número vem de `GET /estado/{carteira}`.
   O canvas continua animando, mas é enfeite — a verdade é do servidor.
3. Servidor passa a ler os heróis da chain (hoje o jogo lê direto).
4. Conversão de dólar para ação acontece no servidor, com preço lido lá.
   Hoje o preço vem do navegador e é editável pelo console.

Quando isso fechar, o jogo fica **honesto** na testnet e a fase A do plano de
segurança tem seu maior item resolvido.

## Depois disso

### Fechamento de época e Merkle
Servidor fecha a época, calcula quem ganhou quanto, publica a raiz no
`RewardVault`. O `CofreTeste` sai de cena — ele paga sem checar nada, de
propósito, e **não pode existir na mainnet**.

### Exigir carteira
Hoje o caminho on-chain é opcional, e opcional significa que ninguém usa.
Custo: quem não tiver carteira para de conseguir testar. O inventário de
demonstração sai junto.

### Commit-reveal no mint
O seed vem de blockhash; com sequenciador único, quem opera influencia.
**Provado explorável:** um contrato chama, lê a raridade e reverte se não gostar
— 40 tentativas ruins custaram zero $BSTOCK. O `HeroNFT_v2.sol` tem a solução,
mas com 5 raridades: precisa virar 6.

### Multisig
Uma chave é dona de tudo e vive num container.

## Pendente de decisão do G

1. **Ícones das skills** — os sete atuais foram desenhados para o jogo. G quer
   os do Bombcrypto; Claude recusou (arte protegida) e os acervos livres não têm
   ícone para skills específicas como "passar por bloco". Aberto: refinar os
   atuais ou encomendar de um ilustrador.
2. **A jaula fura o preço do herói** — é a única fonte de herói que não passa
   pelo caixa. Rara (12% dos mapas), mas existe de propósito?
3. **Devolver 0,001 ETH** parado na Robinhood MAINNET (dinheiro real): falta o G
   informar o destino.
4. **Trocar o token do Railway** quando terminar: passou pela conversa.
5. **Terceiro baú** (800 hp) desligado por falta de arte temática.
6. **Rocha própria da Green Field** — única sem rocha temática.
7. **Travar as minas** (`VENDA_DE_MINA=false`) para lançamento em etapas.

## Dívidas técnicas

- `CofreTeste.sol` paga sem prova nenhuma. **Não vai para a mainnet.**
- `MiniPool.sol` não emite cota de liquidez: quem põe não tira. Testnet só.
- Aprovação ilimitada de $BSTOCK ao cofre e ao contrato do herói.
- Em 1024x600 com a lista cheia a página rola 148px; zerar deixaria o mapa
  com 173px, inutilizável.
