-- BOMBSTOCK — esquema do servidor autoritativo.
-- Regra que manda em tudo: NADA de estado em memoria. Cada ciclo le, calcula e
-- grava. Reiniciar o servidor nao pode custar progresso a ninguem, porque o G
-- vai publicar varias vezes por dia.

create table if not exists jogador (
  carteira      text primary key,              -- minusculo, sempre
  criado_em     timestamptz not null default now(),
  visto_em      timestamptz not null default now(),
  desafio       text,                          -- o texto EXATO que foi pedido
  desafio_expira timestamptz
);

-- Os numeros da economia vivem AQUI, nao no codigo. Trocar densidade ou preco
-- e um update, nao um deploy.
create table if not exists config (
  chave   text primary key,
  valor   numeric not null,
  nota    text,
  mudado_em timestamptz not null default now()
);

insert into config (chave, valor, nota) values
  ('densidade',        0.40,  'fracao de celulas livres que viram bloco'),
  ('limpo_bps',        0.10,  'refaz o mapa abaixo desta fracao de blocos'),
  ('regen_ms',         120000,'ms por ponto de energia recuperado'),
  ('min_saque',        10,    'shares minimas para sacar'),
  ('taxa_saque',       0.03,  'taxa cobrada no saque'),
  ('vagas',            10,    'herois por mina'),
  ('preco_pacote1',    10,    'BSTOCK por heroi'),
  ('paga_madeira',     1.00,  'shares pelo bau facil'),
  ('paga_pedra',       2.31,  'shares pelo bau dificil'),
  ('epoca_horas',      24,    'duracao da epoca')
on conflict (chave) do nothing;

-- Uma mina por jogador por tema. O estado do mapa e serializado aqui.
create table if not exists mina (
  id            bigserial primary key,
  carteira      text not null references jogador(carteira) on delete cascade,
  tema          text not null,                 -- verde, NVDA, GME...
  grade         jsonb,                         -- blocos e vidas
  limpas        int  not null default 0,
  achados       numeric not null default 0,
  atualizada_em timestamptz not null default now(),
  unique (carteira, tema)
);

-- Espelho do que a chain diz. A verdade e a chain; isto e cache com carimbo.
create table if not exists heroi (
  token_id    bigint primary key,
  carteira    text not null,
  raridade    smallint not null,
  personagem  smallint not null,
  power       smallint not null,
  stamina     smallint not null,
  speed       smallint not null,
  bombas      smallint not null,
  alcance     smallint not null,
  skills      smallint not null,
  -- estado de jogo, este sim do servidor
  energia     numeric not null default 0,
  mina_id     bigint references mina(id) on delete set null,
  gx          smallint,
  gy          smallint,
  estado      text not null default 'parado',
  achados     numeric not null default 0,
  sincronizado_em timestamptz not null default now()
);
create index if not exists heroi_por_carteira on heroi (carteira);
create index if not exists heroi_por_mina on heroi (mina_id);

-- Quanto cada carteira minerou de cada acao, por epoca. E isto que vira a raiz
-- de Merkle no fechamento.
create table if not exists saldo_epoca (
  epoca     int not null,
  carteira  text not null,
  ticker    text not null,
  shares    numeric not null default 0,
  primary key (epoca, carteira, ticker)
);

create table if not exists epoca (
  numero      int primary key,
  aberta_em   timestamptz not null default now(),
  fechada_em  timestamptz,
  raiz        text,
  publicada_em timestamptz
);

-- Toda mudanca de saldo deixa rastro. Sem isto nao ha como auditar um saque
-- contestado nem detectar abuso.
create table if not exists evento (
  id        bigserial primary key,
  quando    timestamptz not null default now(),
  carteira  text,
  tipo      text not null,      -- bau, saque, mint, login, erro
  detalhe   jsonb
);
create index if not exists evento_por_carteira on evento (carteira, quando desc);
