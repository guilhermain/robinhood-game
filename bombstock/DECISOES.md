# BOMBSTOCK — decisões e o número que as sustenta

Regra do projeto: isto é uma **réplica da primeira versão do Bombcrypto**.
Quando uma pergunta tiver resposta no original, vale o original.
Divergência só existe se estiver listada aqui como consciente.

## Fiel ao Bombcrypto (não mudar sem motivo)

| coisa | valor | fonte |
|---|---|---|
| Chances de raridade | 82,87 / 10,36 / 5,18 / 1,04 / 0,52 / 0,04% | tabela divulgada da v1 |
| Faixas de stat | power, stamina e speed 1–18; bombas e alcance 1–6 | guias da v1 |
| Velocidade | speed 1 = 1 bloco por segundo | guias da v1 |
| Energia | stamina × 50; 1 bomba = 1 energia; recarga 0,5/min | guias da v1 |
| Vida do baú | marrom 80, roxo 170, dourado 800, prisão 2.000 | whitepaper |
| Pagamento do baú | 0,0143 / 0,033 / 0,163 BCOIN — normalizado para 1 / 2,31 / 11,4 | whitepaper |
| Skills | as 7 da v1, sorteadas de 0 a 2 por herói, sem garantia por raridade | guias da v1 |
| Bloco prisão | resgata um herói ao ser quebrado | whitepaper |
| Herói dorme muito | ~88% do tempo; o jogo é de conferir, não de assistir | comportamento da v1 |

## Divergências conscientes

**Rocha sem prêmio.** No original a tabela lista só baús e prisão. A rocha é
nossa e existe para dar obstáculo ao mapa — sem ela o alcance da bomba não
importa, porque não há nada para contornar. Decidido em 15/09, não "corrigir".

**Recompensa em stock, não em token inflacionário.** É a mudança central do
projeto em relação ao original, e o motivo de ele existir.

**Sem casa na primeira versão.** A arte existe no pacote, sem uso.

**Mapa fixo 19x13.** O original não documenta o tamanho. Fixo porque antes a
grade nascia do tamanho da janela e qualquer zoom refazia o cenário.

**Sete minas só visuais.** Mapa, blocos e recompensa idênticos entre elas.

## Números nossos, com a medição que os escolheu

| parâmetro | valor | por quê |
|---|---|---|
| Densidade de bloco | 0,40 | testadas 0,38 / 0,44 / 0,50: a menor deu menos baú cercado (27,2% contra 41,1%) e mais moeda |
| Baú com lado livre | garantido na geração | sem isso 49,3% dos baús nasciam emparedados; caiu para 23,6% |
| Mapa se refaz | abaixo de 10% de blocos | sem reposição o mapa virava o gargalo: travava em 280 baús/h com 1 ou 15 heróis |
| Transição | 1,9 s, troca escondida na metade | trocar o chão à vista fazia blocos surgirem do nada |
| Animação de plantar | 900 ms | medido: custo zero de vazão, porque o herói é limitado por energia, não por tempo |
| Vagas por mina | 10 | |
| Creator tax na Pons | 3% | escolha do G; com 1% a receita seria 1,7% do volume, com 3% é 3,7% |
| Par da moeda | USDG | as stocks pareiam contra USDG; a fee chega no ativo certo, sem swap |
| Payback do jogador | 60–120 dias | escolha do G, vindo do plano da amiga |

## Vazão medida (build de 15/09)

| time | moedas/h | mapas limpos/h | tempo dormindo |
|---|---|---|---|
| 10 Elon (topo) | 386 | 8,5 | 87,9% |
| misto realista | 41 | 0,83 | 89,4% |

Misto realista = 6 comuns, 2 raros, 1 super raro, 1 épico — o que sai comprando
pacotes de verdade. A diferença entre topo e realista é 9,4x.


## O jogo distribui, não cria (achado de 15/09)

Montando a conta do payback, as unidades mineradas **se cancelaram dos dois
lados**:

    valor de 1 share = (ação que entrou no cofre) / (shares produzidas no total)
    retorno do jogador = shares dele x valor de 1 share

Logo: **o jogo não cria ação, distribui a que o cofre comprou.** Minerar mais
rápido não traz mais NVDA para dentro do jogo — traz mais shares disputando a
mesma NVDA. Todo mundo dilui junto.

Três consequências que valem para sempre:

1. **Balanceamento de vazão não muda o quanto o jogo paga.** Muda só quem leva
   quanto. Se alguém propuser "aumenta o drop para atrair jogador", não
   funciona: dilui todo mundo na mesma proporção.
2. **O preço do pacote não sai da vazão.** Sai de quanto volume de $BSTOCK
   existe por herói: `preço = dias de payback x 2,22% x volume diário / heróis`.
3. **Payback de 60 a 120 dias não é configuração, é aposta em volume futuro.**
   Se o volume não vier, o payback estica sozinho. Foi assim que o Bombcrypto
   quebrou. Recomendação: não prometer payback; usar a fórmula como monitoramento.

Vazão medida por raridade (build de 15/09, moedas por hora por herói, 8h
simuladas): Common 0,89 · Rare 4,28 · Super Rare 7,39 · Epic 15,17 ·
Legendary 20,85 · S. Legendary 24,85. Herói médio de pacote: 1,84/h = 44,1/dia.

## Vocabulário

A unidade minerada chama-se **share** na interface, não "coin". Ela é fração da
ação da mina, não uma segunda moeda. O nome "coin" foi usado de 15/09 até a
troca e causou confusão: parecia existir um token intermediário, que não existe.

## Pipeline de arte (para não repetir erro)

As folhas vêm com fundo magenta ou branco e **borda suavizada**, apesar de o
LEIA-ME dizer que não têm. Recortar por cor pura deixa franja cinza no contorno.

O caminho que funciona:
1. fundo por componentes conectados a partir da borda, com **limiar escolhido
   por quadro** — desce enquanto a perda de área ficar abaixo de 3,5%. Limiar
   fixo baixo come cabelo grisalho; limiar fixo alto deixa franja;
2. sangramento da cor opaca para dentro da área transparente antes de reduzir;
3. redução com LANCZOS e, para sprite de jogo, alfa binário com desfranjamento;
4. para retrato exibido 1:1, **alfa suave** e webp — alfa binário vira serrilhado.

Resultado: franja em 1,7% das folhas de sprite e 0,8% nos retratos.
