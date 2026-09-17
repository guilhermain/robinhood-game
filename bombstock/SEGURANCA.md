# BOMBSTOCK — auditoria de segurança e plano para ir ao ar

Feita em 17/09/2026, com ataques executados de verdade na testnet 46630, não só
lidos no código. Cada item diz o que foi testado e o que aconteceu.

## Resumo em uma linha

**Hoje o jogo é drenável em minutos por qualquer pessoa com um contrato.**
Isso é esperado na testnet e é FATAL na mainnet. Nada do que está no ar pode
receber dinheiro real sem os itens marcados CRÍTICO abaixo resolvidos.

---

## CRÍTICO — bloqueia o lançamento

### 1. O cofre paga o que o cliente pedir
**Testado:** um contrato de 8 linhas chamou `sacar` vinte vezes numa transação
e levou **20.000 NVDA do cofre sem ter minerado nada**. Gas: 242 mil.

**Causa:** `CofreTeste` não verifica quanto foi minerado, porque não existe
quem possa verificar. A quantidade nasce no navegador do jogador.

**Correção:** servidor autoritativo que roda a simulação e publica a raiz de
Merkle no `RewardVault` (já escrito e testado, sete ataques bloqueados). O
`CofreTeste` **não existe na mainnet**, ponto.

### 2. Re-roll no mint
**Testado:** um contrato chamou `abrirPacote`, leu a raridade no mesmo bloco e
reverteu quando não gostou. **Quarenta tentativas ruins custaram zero $BSTOCK.**
Só o gas. Quem usa contrato paga apenas pelos heróis bons; a curva de raridade
deixa de existir para ele.

**Causa:** sorteio e entrega na mesma transação, com semente de `blockhash` e
`timestamp` que o chamador consegue observar antes.

**Correção:** commit-reveal em duas transações, com assinatura do servidor
entrando na semente. O `HeroNFT_v2.sol` já implementa isso e precisa ser
adaptado para as seis raridades. Alternativa mais barata: bloquear chamadas
de contrato (`msg.sender == tx.origin`) — mitiga o re-roll automático mas não
a previsibilidade da semente.

### 3. Uma chave manda em tudo
A carteira de deploy é dona de todos os contratos, operadora do cofre e vive
em disco num container. Se ela vazar, tudo cai.

**Correção:** multisig (Safe) como dono; operador do cofre separado e rotativo;
chave de deploy descartada após o deploy. Já verificado: **a chave NÃO está no
repositório** nem em nenhum arquivo publicado.

---

## ALTO — resolver antes ou logo depois do lançamento

### 4. Aprovação ilimitada de $BSTOCK
O jogo pede `approve` de valor infinito para o cofre e para o contrato do herói.
Se qualquer um desses contratos tiver um bug, o atacante leva TODO o $BSTOCK da
carteira do jogador, não só o do pacote.

**Correção:** aprovar o valor exato de cada compra. Custa uma assinatura a mais
por compra; é o preço da contenção.

### 5. Preço do pacote fixo em token
Pacote custa 10 $BSTOCK. Se o token cair 90%, o pacote fica 90% mais barato,
a produção de heróis explode, e o token cai mais. É a espiral que matou o
Bombcrypto.

**Correção:** preço em dólar, cobrado em $BSTOCK pela cotação do pool no momento.

### 6. Buyback previsível
A conversão em lote no fechamento da época vira um pico de compra num horário
conhecido. Quem observa a chain compra antes e vende em cima.

**Correção:** espalhar o swap em pedaços aleatórios ao longo de horas.

### 7. Sem limite de emissão na testnet
`torneira()` dá 1.000 $BSTOCK a qualquer carteira, sem fim. Na testnet é
desejado. **Não pode existir no token da mainnet** — lá o $BSTOCK sai da Pons.

---

## MÉDIO

### 8. Estado do jogo editável pelo console
`cofreAcao`, `saldo`, `minas`, `FRACAO`, `MIN_SAQUE` são variáveis globais.
Editar não afeta a chain (o contrato tem os próprios números), mas afeta a
tela e, hoje, o quanto o cliente pede ao cofre — que é o item 1.

### 9. Pool sem retirada de liquidez
`MiniPool.adicionar` não emite cota. Quem colocou não tira. Na testnet tanto
faz; na mainnet o pool é o da Pons e este contrato não existe.

### 10. Dependência de fonte de preço externa
Cotação vem do GeckoTerminal. Se cair, a tela mostra tracinho — correto. Mas
se for envenenada, a tela mostra preço errado. O contrato não usa esse preço,
então o dano é só de exibição.

---

## BAIXO / OK

- **XSS:** um único `innerHTML` com dado dinâmico, e o dado é constante do
  código (tabela de raridade). Endereço da carteira entra por `textContent`.
- **Dependências externas:** só RPC, GeckoTerminal, Google Fonts e explorer.
  Nenhum JavaScript de terceiros.
- **Segredos:** chave privada e token do GitHub verificados fora do repositório
  e do HTML publicado.
- **Merkle vault:** sete ataques bloqueados (saque duplo, valor maior, prova
  alheia, época inexistente, publicar sem ser operador, republicar, recolher
  sem ser dono).

---

## Plano para ir ao ar, em ordem

**Fase A — fundação (sem isto não há lançamento)**
1. Servidor autoritativo: simulação da mina, login por assinatura, banco.
2. Fechamento de época + publicação de raiz no `RewardVault`.
3. `HeroNFT` com commit-reveal e seis raridades.
4. Multisig como dono de todos os contratos.

**Fase B — endurecimento**
5. `approve` do valor exato.
6. Preço do pacote ancorado em dólar.
7. Swap do buyback espalhado.
8. Rate limit e monitoramento na RPC própria (não depender só da pública).

**Fase C — antes de abrir a porta**
9. Auditoria externa dos contratos de mainnet. Não os de teste: os que vão
   receber dinheiro.
10. Testnet pública por pelo menos duas semanas com recompensa por bug.
11. Lançamento com **teto de saque por época** e **pausa de emergência** nos
    contratos. Se algo der errado, para em uma transação.

**O que NÃO fazer**
- Apontar o jogo atual para a mainnet trocando só os endereços. Ele seria
  drenado no mesmo dia.
- Lançar sem multisig. Uma chave, um ponto de falha.
- Confiar em `msg.sender == tx.origin` como solução do re-roll. É paliativo.


---

# Segunda rodada — sessão e concorrência (17/09, tarde)

A primeira rodada olhou contratos e a contagem no cliente. **Não olhou sessão,
concorrência nem estado duplicado.** O G perguntou "por que consigo abrir duas
janelas?" e a pergunta expôs a lacuna. Tudo abaixo foi executado, não lido.

## CRÍTICO — encontrado e corrigido

### 5. Qualquer um agia em nome de qualquer carteira
**Testado:** `POST /mina/entrar` com a carteira de outra pessoa, **sem assinar
nada**, respondeu 200 e moveu três heróis dela para outra mina.

**Causa:** o login verificava a assinatura e depois esquecia. Nada ligava as
chamadas seguintes à prova. Não era roubo de dinheiro, mas era agir na conta
alheia: tirar heróis da mina, mandar para outra ação.

**Correção:** o login emite um token de 24h, guardado como hash no banco; toda
ação exige `Authorization: Bearer`. Testado: sem token 401, token inventado
401, token de A usado em B 401, token após logout 401. Confirmado em produção.

## MÉDIO — encontrado, ainda aberto

### 6. Duas abas no modo local se sobrescrevem
**Testado:** duas abas sem carteira, cada uma minerou; a última a salvar venceu
e o progresso da outra sumiu ao recarregar. **Perde dinheiro, não duplica** — é o
oposto de um exploit, mas o jogador vai achar que foi roubado.

Com sessão no servidor não acontece: as duas abas leem o mesmo número e nenhuma
cria nada (testado: 30 baús no console em cada aba, saldo inalterado).

Correção pendente: aviso de "aberto em outra aba" via `storage` event, ou
travar o modo local a uma aba.

## OK — testado e passou

- Save local não vaza para outra carteira ao conectar.
- Login com assinatura lixo: 401.
- Ler o estado de qualquer carteira é possível — e é intencional: o estado é
  público como um saldo na chain. Ler não é agir.
- Sessão persistida por navegador com validade: recarregar não exige assinar de
  novo; carteira diferente exige.

## O que esta rodada me ensinou
Auditar só o que dá dinheiro deixa passar o que dá **controle**. Mover os
heróis de alguém não rouba um centavo e ainda assim é invasão de conta.
