# BOMBSTOCK — plano para virar jogo cripto

Escrito em 15/09/2026, depois de eu propor peças soltas fora de ordem.
Este arquivo manda; `PROXIMOS_PASSOS.md` é a lista curta do dia.

**Atualizado em 18/09:** as etapas 1 e 2 fecharam. A seção 1 abaixo descreve o
jogo de 15/09 e está mantida como registro histórico; o estado atual está em
`PROXIMOS_PASSOS.md`, e o que falta para a mainnet em `MAINNET.md`.

## 1. O que existe hoje

**O jogo.** Um HTML de 577 KB, 66 funções, 6 telas, 7 minas, 62 folhas de arte.
Roda em `bombstock/play/`. Mecânica auditada peça por peça em 15/09: energia,
as 7 skills, dano, pagamento por tipo de baú, prisão e a curva de raridade em
100 mil sorteios — dez de dez batendo com o esperado.

**O site.** Homepage em `bombstock/`, 26 elementos interativos, 24 com efeito.

**Persistência.** Progresso salvo no navegador. Sobrevive ao reload. Editável
pelo jogador.

**Cripto de leitura.** Conecta carteira, troca para a chain 4663, lê preço das
sete ações ao vivo, lê saldo real da carteira, e cada mina credita moeda na sua
própria ação. Nada escreve na chain.

## 2. O que impede o jogo de ser cripto de verdade

Um fato só, e ele explica todo o resto:

> **A quantidade minerada nasce no navegador do jogador.**

`bausCofre` é variável de JavaScript. Qualquer um abre o console e escreve o
número que quiser. Isso não se resolve com ofuscação, assinatura no cliente nem
contrato esperto: quem produz o número é a máquina de quem ganha.

Consequência, e é a regra que organiza o plano inteiro:

> **Nada que dependa de quanto foi minerado pode ir para a mainnet antes do
> servidor. Tudo que não depende disso, pode ir antes.**

É essa linha que eu estava cruzando sem perceber ao propor deploy solto.

## 3. Os dois lados

**Lado A — não depende do quanto minerado.** Pode ir para mainnet quando quiser:
identidade do jogador, posse de herói, compra de pacote paga em token, lançamento
do $BSTOCK, compra de mina. Nada aqui pergunta quanto você produziu.

**Lado B — depende do quanto minerado.** Só existe com servidor: o Claim, o
RewardVault, a distribuição das ações, o fechamento de época.

## 4. Ordem proposta

### Etapa 0 — decidir, não codar
As mecânicas estão auditadas, mas o balanceamento não está fechado. Pôr em
contrato o que ainda muda é lacrar alvo móvel. Três decisões travam o Lado A:
- raridade em 5 ou 6 níveis (hoje 6, decidido não mexer agora)
- preço e tamanho de pacote, hoje 10/48/90 em número solto
- se comprar mina dá vantagem de jogo ou continua só a ação em que se é pago

### Etapa 1 — testnet 46630, caminho de escrita inteiro — FEITA em 16/09
Chain 46630, RPC `https://rpc.testnet.chain.robinhood.com`, CORS liberado,
faucet público. Aqui a trapaça não custa nada, então dá para montar tudo:
1. $BSTOCK de teste
2. `HeroNFT` — já escrito, 7 testes passando no Foundry
3. seis ERC-20 imitando as ações
4. RewardVault e o Claim virando transação de verdade

Sai daqui um jogo **funcional de ponta a ponta** sem risco: conecta, compra,
recebe, minera, saca, vê o token chegar na carteira.

### Etapa 2 — servidor — FEITA em 17/09 (Railway, keeper no ar)
Só depois da testnet provar o caminho. Simulação no servidor, login por
assinatura, banco, fechamento de época, raiz Merkle. É o que destrava a mainnet.

### Etapa 3 — mainnet — ver `MAINNET.md`
Lado A pode ir antes, se você quiser adiantar. Lado B só depois da etapa 2.

## 5. O que NÃO fazer

- Deployar contrato que fixe balanceamento antes da etapa 0.
- Pagar em mainnet sem servidor. É drenável na primeira hora.
- Trocar ordem por empolgação: cada peça do Lado B depende do servidor, e o
  servidor depende de saber se o jogo prende.

## 6. A pergunta que nenhuma medição minha responde

O salvamento acabou de existir. Ninguém ainda viveu o laço idle — fechar,
voltar horas depois, decidir o que fazer. Antes de gastar em servidor e
hospedagem, vale saber se vocês voltam.
