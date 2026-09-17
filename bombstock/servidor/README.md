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
- [ ] Simulação da mina no servidor
- [ ] Endpoint de estado (o cliente para de contar e passa a só desenhar)
- [ ] Fechamento de época e raiz de Merkle
- [ ] Deploy no Railway (bloqueado: trial da conta expirou)

## Rodar local

`DATABASE_URL` vazio sobe um Postgres embutido em `/home/claude/pgdata`.
Com a variável preenchida, usa o banco de verdade.
