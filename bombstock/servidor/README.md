# BOMBSTOCK — servidor autoritativo

Existe por um motivo só: **hoje a quantidade minerada nasce no navegador do
jogador**, e um contrato de oito linhas drena o cofre (ver `SEGURANCA.md`,
ataque 1). Enquanto a conta não sair da máquina de quem ganha, nada pode pagar
dinheiro real.

## Regra que manda na arquitetura

**Nada de estado em memória.** Cada ciclo lê do banco, calcula e grava. O G
publica várias vezes por dia; reiniciar o servidor não pode custar progresso a
ninguém. Se algum dia aparecer um cache "só para acelerar", ele quebra isso.

## Os números da economia vivem no banco

Tabela `config`: densidade, drop, preço do pacote, mínimo de saque, duração da
época. Trocar 0,40 por 0,38 é um `update`, não um deploy. Foi decisão explícita
para o G poder calibrar sem republicar.

## Login por assinatura

Sem senha, sem e-mail, sem nada que possa vazar. A carteira prova quem é
assinando um texto que o **servidor** sorteou.

Três regras, e cada uma fecha um ataque:
1. O desafio é sorteado pelo servidor e **o texto exato fica no banco**. Se o
   cliente escolhesse o texto, ele mandaria assinar qualquer coisa.
2. Vence em 5 minutos e é **queimado no uso**. Uma assinatura, um login.
3. O texto nomeia o domínio e a carteira, então assinatura feita para outro
   site não vale aqui.

Testado com ataques reais (`python3 -m pytest` não; script direto):
reuso da assinatura, assinatura de outra chave, texto escolhido pelo atacante,
assinatura malformada, carteira vazia, desafio expirado e desafio de uma
carteira usado por outra. **Sete tentativas, sete bloqueios**, e o caminho
honesto passa.

## Estado

- [x] Esquema do banco, aplicado e testado em Postgres real
- [x] Login por assinatura, com os sete ataques bloqueados
- [x] **Sessão com token** (24h, hash no banco). Antes qualquer um agia em nome de qualquer carteira
- [x] Simulação da mina por evento: mil minas custam 6,5% de um núcleo
- [x] Economia em dólar; payback de 30 dias confirmado em 240h
- [x] `/estado`: o cliente para de contar e passa a só desenhar
- [x] Servidor lê os heróis da chain e confere propriedade antes de descer
- [x] Fechamento de época: congela dólar e cotação, monta Merkle, serve prova
- [x] **Keeper**: fecha e publica sozinho, alinhado com `epocaAtual()` do contrato
- [x] Deploy no Railway: https://robinhood-game-production-3577.up.railway.app
- [x] Lista fechada de temas, lock por carteira, limite por carteira nas ações

## Endpoints

| rota | o que faz |
|---|---|
| `POST /login/desafio` | sorteia o texto a assinar |
| `POST /login/verificar` | confere a assinatura, emite o token |
| `POST /logout` | invalida o token |
| `POST /mina/entrar` | desce heróis; exige sessão; confere na chain |
| `GET /estado/{carteira}` | o que o cliente desenha |
| `GET /epoca/estado` | onde as épocas estão |
| `GET /epoca/{n}/previa` | o que a época pagaria |
| `GET /epoca/{n}/prova/{carteira}` | a prova para o contrato; só de época fechada |
| `POST /epoca/fechar` | congela e abre a próxima; só com `KEEPER_CHAVE` |

## Variáveis de ambiente

`DATABASE_URL`, `CHAIN_RPC`, `CHAIN_ID`, `HEROI_ADDR`, `VAULT_ADDR`,
`KEEPER_CHAVE` (fecha época por HTTP), `KEEPER_PK` (assina a publicação; sem ela
o keeper não roda), `EPOCA_HORAS` (24).

## Aberto

Ver `../SEGURANCA.md` achados 11 a 15 e `../MAINNET.md`.

## Rodar local

`DATABASE_URL` vazio sobe um Postgres embutido em `/home/claude/pgdata`.
Com a variável preenchida, usa o banco de verdade.
