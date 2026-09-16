# BOMBSTOCK — próximos passos

Atualizado em 15/09/2026, depois da camada cripto de leitura.
Fonte de verdade do que falta. Leia o `DECISOES.md` em seguida.

## Onde as coisas estão

| | endereço |
|---|---|
| Site | https://guilhermain.github.io/robinhood-game/bombstock/ |
| Jogo | https://guilhermain.github.io/robinhood-game/bombstock/play/ |
| Fonte | repo `guilhermain/robinhood-game`, pasta `bombstock/` |

Jogo: HTML único de ~600 KB, toda a arte em base64. Publicação por commit na
API do GitHub; o Pages leva de 60 a 90 segundos.

## O bloqueio que manda em tudo

O jogo roda inteiro no navegador. As moedas são variável de JavaScript e
qualquer um edita pelo console. **Enquanto for assim, nenhum pagamento em stock
pode existir** — seria drenado na primeira hora. O servidor autoritativo não é
uma melhoria, é pré-requisito de qualquer coisa que pague.

## Próximo passo recomendado: metade 2 do cripto

1. **Servidor autoritativo.** A simulação da mina roda no servidor; o cliente só
   desenha. O cliente nunca informa que achou baú.
2. **Login por assinatura de carteira** (SIWE), sem senha nem e-mail. A carteira
   já conecta no cliente; falta o lado que confia nela.
3. **Banco.** Heróis, energia, moedas por época, estado das minas.
4. **Fechamento de época.** Soma as moedas por carteira e por ação, e congela.
5. **RewardVault e distribuidor.** Raiz Merkle publicada, claim puxado pelo
   jogador. Pull, nunca push.
6. **Keeper.** Recolhe a fee, fecha a época, publica a raiz.

Antes disso, uma coisa barata e que muda a percepção: **salvar o progresso**.
Hoje recarregar a página zera tudo. Mesmo sem servidor, guardar no navegador já
elimina a reclamação mais óbvia de quem testa.

## Pendente de decisão do G

1. **Raridade: 5 ou 6 níveis.** Jogo tem 6 (escala do Bombcrypto), site tem 5.
   Decidido em 15/09: fica em 6, não mexer por enquanto.
2. **Identidade visual.** Site é roxo com laranja e usa Inter; jogo é âmbar sobre
   marrom e usa Archivo. Duas identidades convivendo.
3. **Mínimo de saque.** 40 moedas. No original equivalia a ~2.800 baús marrons.
4. **Quantidade de baú no mapa.** 28,7 por mapa, 51% dos blocos. G achou demais.
5. **O terceiro baú.** As folhas por mina vieram com dois tipos, então o baú de
   800 de vida está desligado em todas. Volta quando a arte existir por tema.
6. **Comprar mina não dá vantagem de jogo.** Todas rendem igual; a diferença é a
   ação em que você é pago. Se quiser risco e retorno diferentes, os ganchos são
   densidade, proporção entre baús e chance de prisão.
7. **Rocha própria da Green Field.** É a única das sete que ainda usa a pedra
   cinza genérica; as outras seis ganharam rocha temática.
8. **Travar as minas de novo.** Estão liberadas para teste. Trocar
   `VENDA_DE_MINA` para `false` quando quiser lançar aos poucos.

## Pronto e verificado

Fase 1 fechada: mina, IA, 7 skills, 6 raridades, prisão, loja, abertura de carta,
inventário, squad, saque, transição ao limpar, navegação em abas, descritivo de
skill por hover e toque.

Sete minas com cenário, rocha, jaula e dois baús próprios. Uma mina por vez: a
equipe inteira acompanha a troca.

Cripto de leitura: carteira conecta e troca para a chain 4663, preço das ações
lido ao vivo, cada mina paga na sua ação, saque separado por ação com o saldo
real da carteira.

Auditoria de mecânica (15/09), cada uma medida contra o esperado: energia,
Save Battery 19,9%, Fast Charge 1,70x, dano por power, Treasure Hunter, Jail
Breaker, Pierce Block, Block Pass, Bomb Pass, pagamento por tipo de baú, mina
definindo a ação, prisão liberando herói e a curva de raridade em 100 mil
sorteios. Dez de dez corretas, zero erro de console.

## Dívidas técnicas

- Progresso não é salvo.
- Dois arneses de simulação dão números absolutos incompatíveis (800 moedas/h
  contra 30 na mesma configuração). Só comparação dentro da mesma rodada é
  confiável. Precisa de investigação separada.
- Inventário de demonstração (um de cada personagem + 10 Elon) e saldo inicial de
  200 estão marcados no código e saem quando a economia for pra valer.
- O contrato `HeroNFT`, escrito e testado em Foundry com 7 testes passando, vive
  só no histórico da conversa. Precisa ir para o repositório.
