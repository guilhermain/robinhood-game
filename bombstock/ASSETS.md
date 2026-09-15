# BOMBSTOCK — inventário de arte

## Embutido no jogo hoje

| conjunto | folhas | origem |
|---|---|---|
| Caminhada dos personagens | 8, 16 quadros cada | `personagens-sprites-finais-2x/*/WASD.png` |
| Plantar bomba | 8, 64 quadros cada | `personagens-sprites-finais-2x/*/bomba_*.png` |
| Retratos da carta | 8, 128x144, webp com alfa suave | mesma folha WASD, linha de frente |
| Cenário por tema | 7 | `cenarios_6_minas` + `cenario_verde_e_prisao` |
| Jaula por tema | 6 | `jaulas_6_stocks_sem_olhos` |
| Rocha, bomba, fogo | 3 | `assets_mapa_final/png_1x` |
| Baús | 3 folhas de 8 quadros | imagens soltas enviadas pelo G |
| Ícones de atributo | 1 tira de 6 | recortados de `08_itens_icones`, `03_bomba`, `04_fogo` |

## No pacote e ainda sem uso

- **`06_prisao`** — pegada 2x2, e o bloco do jogo ocupa 1 tile. Só serve se a
  prisão virar uma estrutura de 2x2.
- **`07_casas_descanso`** — quatro casas. Fora porque a casa saiu da v1.
- **`08_itens_icones`** — 8 ícones; 4 viraram a tira de atributos, o resto
  espera itens que o jogo ainda não tem.
- **O oitavo tile de cada cenário (`grade`)** — era a prisão antes das jaulas.

## Entregue em 15/09 e ainda não embutido

- `baus_finalizados_7_minas_14_folhas` — 2 baús por mina, 7 minas
- `jaulas_finalizadas_7_minas` — 1 por mina, 4 quadros
- `minas_6_conjuntos_24_folhas` — cenário, destrutíveis, jaula e baús por tema

## Site

25 arquivos em `bombstock/assets/`, com `manifest.json` registrando dimensão,
transparência e origem de cada um. Os logos das ações são reconstruções em
pixel art, não vetor oficial da marca.
