# BOMBSTOCK — próximos passos

Atualizado em 15/09/2026. Este arquivo é a fonte de verdade do que falta.
Quem mexer no projeto lê isto primeiro e o `DECISOES.md` em seguida.

## Onde as coisas estão

| | endereço |
|---|---|
| Site | https://guilhermain.github.io/robinhood-game/bombstock/ |
| Jogo | https://guilhermain.github.io/robinhood-game/bombstock/play/ |
| Fonte | repo `guilhermain/robinhood-game`, pasta `bombstock/` |

O jogo é um HTML único de ~490 KB com toda a arte embutida em base64.
Publicação: commit pela API do GitHub; o Pages leva de 60 a 90 segundos.

## Pendente de decisão do G

1. **Raridade: 5 ou 6 níveis.** O site tem cinco rótulos (Common, Rare, Epic,
   Legendary, Mythic) e o jogo tem seis (com Super Rare e S. Legendary, que é a
   escala da v1 do Bombcrypto). Enquanto não fechar, as duas telas contam
   histórias diferentes.
2. **Identidade visual.** O site é roxo com laranja e usa Inter; o jogo é âmbar
   sobre marrom escuro e usa Archivo. São duas identidades.
3. **Mínimo de saque.** Está em 40 moedas. Com o marrom valendo 1, isso são
   ~40 baús. No original o mínimo equivalia a quase 2.800 baús marrons.
4. **Quantidade de baú no mapa.** G achou demais; medido em 28,7 baús por mapa,
   51% dos blocos. Opções levantadas: baixar a densidade, aumentar a proporção
   de rocha, ou reduzir o tamanho do sprite do baú.
5. **O link antigo.** `bombstock/` agora abre o site, não o jogo. Se alguém tem
   o link salvo esperando cair na mina, vai estranhar.

## Arte recebida e ainda não aplicada

Quatro zips entregues em 15/09. O item 4 (site) já foi aplicado. Faltam:

- **`baus_finalizados_7_minas_14_folhas`** — 2 baús por mina nas 7 minas,
  8 quadros cada, 1774x887, fundo magenta. Resolve a falta de arte para o
  terceiro nível de dificuldade.
- **`jaulas_finalizadas_7_minas`** — 1 por mina, 4 quadros, 2172x724.
  Substitui as `jaulas_sem_olhos` e cobre a mina gratuita.
- **`minas_6_conjuntos_24_folhas`** — 4 folhas por tema: cenário, destrutíveis,
  jaula e baús. O `B_destrutiveis` é novo: hoje a rocha é a mesma cinza nas
  sete minas.

Parece haver sobreposição entre os três: o conjunto de 24 folhas contém jaula e
baús que também vieram soltos. Conferir antes de embutir tudo.

## Fases que continuam abertas

### Fase 1 — jogo (quase pronta)
Pronto: mina, IA dos heróis, 7 skills, 6 raridades, prisão, loja com pacotes,
abertura de carta, inventário, squad, saque, transição ao limpar o mapa,
navegação em abas.
Falta: salvar o progresso (hoje some ao recarregar) e a tela de detalhe do herói.

### Fase 2 — servidor
Nada feito. Hoje o jogo roda no navegador e qualquer um edita os pontos pelo
console. Servidor autoritativo, login por assinatura, banco, fechamento de época.

### Fase 3 — blockchain
Nada deployado. Lançar a moeda na Pons (creator tax 3%, par USDG), contrato do
herói, RewardVault, distribuidor por Merkle, keeper.
O contrato `HeroNFT` foi escrito e testado em Foundry (7 testes passando), mas
vive só no histórico da conversa — precisa ir para o repositório.

### Fase 4 — arte
Faltam: os estados de herói (parado, cansado, dormindo), a prisão em 2x2 e a
casa de descanso, que está no pacote sem uso porque a casa saiu da v1.

### Fase 5 — fora do jogo
Site pronto. Faltam painel público, infra e jurídico.

## Dívidas técnicas conhecidas

- O progresso não é salvo. Recarregou, perdeu tudo.
- Dois arneses de simulação dão números absolutos incompatíveis entre si
  (800 moedas/h contra 30 na mesma configuração). Só comparações dentro da
  mesma rodada são confiáveis. Precisa de investigação separada.
- O inventário de demonstração (um de cada personagem + 10 Elon) está marcado no
  código e precisa sair quando a economia for pra valer.
