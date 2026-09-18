# BOMBSTOCK — o que falta para a mainnet

Atualizado em 18/09/2026, depois de quatro rodadas de auditoria com ataques
executados. Este é o documento de referência para a migração. Cada item diz o
que é, por que bloqueia, e o que resolve.

**Regra que manda em tudo:** nada do que está no ar hoje pode receber dinheiro
real. A testnet foi feita para provar o caminho, não para ser copiada.

---

## Onde estamos

| camada | estado |
|---|---|
| Jogo | no ar, conta a mineração no servidor quando há sessão |
| Servidor | no ar no Railway, login por assinatura, sessão com token, época com Merkle, keeper publicando sozinho |
| Contratos | 9 na testnet 46630; 2 deles **não podem existir** na mainnet |
| Economia | payback de 30 dias medido em 240h; mínimo de saque US$10; preço linear |
| Auditoria | 15 achados em 4 rodadas; 10 corrigidos, 5 abertos |

O ciclo inteiro funciona na testnet: jogador conecta, assina, minta, minera, o
servidor fecha a época, o keeper publica a raiz, o jogador saca com prova.
Provado com carteira real assinando no navegador.

---

## BLOQUEIA — sem isto não há lançamento

### 1. Multisig como dona de tudo
**Hoje:** uma chave só é dona de todos os contratos, operadora do cofre e
assinante do keeper. Foi gerada dentro de um container de IA. Trate como
comprometida.
**Resolve:** um Safe com 2 de 3 assinaturas como dono; uma chave separada e
rotativa só para o keeper, com o mínimo de ETH para gas; a chave de deploy
descartada depois do deploy.
**Depende de:** o G criar o Safe. Não há como fazer por ele.

### 2. Contratos de mainnet escritos e auditados
**Hoje:** os contratos da testnet são de teste. `CofreTeste` paga o que
pedirem (provado: 20.000 NVDA numa transação). `Tokens.sol` tem torneira
aberta. `MiniPool` não emite cota de liquidez.
**Resolve:** na mainnet existem só dois contratos nossos — `HeroNFT` com
commit-reveal e `RewardVault`. As ações são as da Robinhood; o $BSTOCK sai da
Pons; o pool é o da Pons. Os dois precisam de **auditoria externa** antes de
receber um centavo. Custa alguns milhares de dólares. É o maior custo do
projeto e não é opcional.

### 3. Commit-reveal no mint
**Hoje:** sorteio e entrega na mesma transação. Provado explorável: um contrato
chama, lê a raridade e reverte se não gostar. 40 tentativas ruins custaram zero.
**Resolve:** duas transações — compromisso e revelação — com assinatura do
servidor entrando na semente. O `HeroNFT_v2.sol` tem a base, com 5 raridades;
precisa virar 6.

### 4. Carteira obrigatória
**Hoje:** o jogo funciona sem carteira, contando local. Enquanto esse caminho
existir, `sacarOnchain()` continua no código apontando para o `CofreTeste`.
Achado 15 da auditoria.
**Resolve:** matar o modo local. Custo: quem não tem carteira não joga. Na
mainnet isso é o correto.

### 5. Pausa de emergência nos contratos
**Hoje:** não há como parar nada. Contrato não se edita.
**Resolve:** `pause()` no `RewardVault` e no `HeroNFT`, controlado pela
multisig. Se algo der errado, para em uma transação.

### 6. Teto de saque por época
**Hoje:** o cofre paga o que a raiz disser.
**Resolve:** limite absoluto por época no contrato, abaixo do saldo do cofre.
Um bug no servidor não pode esvaziar o cofre numa época só.

---

## ALTO — resolver antes ou logo depois

### 7. Aprovação de valor exato
O jogo pede `approve` infinito de $BSTOCK ao cofre e ao contrato do herói. Um
bug em qualquer um leva a carteira inteira do jogador. Aprovar o valor de cada
compra custa uma assinatura a mais; é o preço da contenção.

### 8. Preço do pacote em dólar
Hoje 10 $BSTOCK fixos. Se o token cair 90%, o herói fica 90% mais barato, a
produção explode e o token cai mais — a espiral do Bombcrypto. Cobrar em
$BSTOCK pela cotação do pool no momento.

### 9. Buyback espalhado
A conversão em lote no fechamento vira um pico de compra em horário conhecido.
Quem observa a chain compra antes. Espalhar em pedaços aleatórios ao longo de
horas.

### 10. Squad não volta ao recarregar
Achado 14: depois de descer e recarregar, o cliente mostra a mina vazia
enquanto o servidor minera com os heróis. Confunde; não rouba.

### 11. Duas abas no modo local se sobrescrevem
Achado 6. Some quando o modo local sair (item 4).

### 12. Limite por IP não funciona no Railway
Achado 11. O proxy troca o IP a cada pedido. Leitura de estado é pública e sem
limite. Resolve com limite na borda (Cloudflare) ou contador no Postgres.

### 13. Amplificação de leitura da chain
Achado 12. Cada entrada na mina lê a chain uma vez por herói. Cache do
inventário por alguns minutos.

---

## MÉDIO

### 14. Volume necessário para sustentar 30 dias
O jogo não cria valor. Payback de 30 dias com 1.000 heróis exige **US$ 15 mil
de volume diário** de $BSTOCK, para sempre. Com 10.000, US$ 150 mil. O número
está na tabela `config` do banco para ser calibrado com volume real, sem deploy.
Isto não é bug — é a conta que precisa fechar.

### 15. A jaula fura o preço do herói
Única fonte de herói que não passa pelo caixa. Rara (12% dos mapas). Decisão do
G se fica.

### 16. Terceiro baú e rocha da Green Field
Arte faltando. Cosmético.

---

## Fora do código, e sem isto nada acontece

- **Lançar o $BSTOCK na Pons V2**, par USDG, taxa de criador 3%.
- **Abastecer o cofre** com a taxa: 60% para ações, 20% time, 10% queima, 10%
  reserva. É isso que faz a economia existir.
- **Devolver 0,001 ETH** da carteira comprometida na mainnet. Precisa do
  endereço de destino do G.
- **Trocar o token do Railway** e revogar o token do GitHub usados nesta
  sessão. Os dois passaram pela conversa.
- **Testnet pública por duas semanas** com recompensa por bug, antes de abrir.
- **Ícones das skills**: decisão pendente do G.

---

## Ordem sugerida

1. Multisig (G)
2. Carteira obrigatória
3. Commit-reveal
4. Contratos de mainnet com pausa e teto
5. Auditoria externa
6. Pons + abastecer o cofre
7. Testnet pública
8. Lançar

Nada de 2 a 8 vale a pena sem 1. E nada vale a pena sem 5.
