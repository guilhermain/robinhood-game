-- BOMBSTOCK — esquema do servidor autoritativo.
-- Regra que manda em tudo: NADA de estado em memoria. Cada ciclo le, calcula e
-- grava. Reiniciar o servidor nao pode custar progresso a ninguem, porque o G
-- vai publicar varias vezes por dia.

create table if not exists jogador (
  carteira      text primary key,              -- minusculo, sempre
  criado_em     timestamptz not null default now(),
  visto_em      timestamptz not null default now(),
  desafio       text,                          -- o texto EXATO que foi pedido
  desafio_expira timestamptz,
  -- Sessao: o login emite um token; toda acao exige ele. Guardado como hash,
  -- porque a tabela nao pode ser a chave da conta de ninguem se vazar.
  sessao_hash   text,
  sessao_expira timestamptz
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
  ('min_saque_usd',    10,    'US$ minimo para sacar; decisao do G'),
  ('usd_bau_marrom', 0.009085, 'US$ por bau marrom; payback 30d do heroi MEDIO, vazao medida em 240h'),
  ('payback_dias',     30,    'meta de payback do heroi, decisao do G'),
  ('preco_heroi_usd',  10,    'preco do heroi em US$'),
  ('taxa_saque',       0.03,  'taxa cobrada no saque'),
  ('vagas',            10,    'herois por mina'),
  ('preco_pacote1',    10,    'BSTOCK por heroi'),

  ('epoca_horas',      24,    'duracao da epoca')
on conflict (chave) do nothing;

-- Uma mina por jogador por tema. O estado do mapa e serializado aqui.
create table if not exists mina (
  id            bigserial primary key,
  carteira      text not null references jogador(carteira) on delete cascade,
  tema          text not null,                 -- verde, NVDA, GME...
  grade         jsonb,                         -- blocos e vidas
  limpas        int  not null default 0,
  achados_usd   numeric not null default 0,
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
  achados_usd numeric not null default 0,
  sincronizado_em timestamptz not null default now()
);
create index if not exists heroi_por_carteira on heroi (carteira);
create index if not exists heroi_por_mina on heroi (mina_id);

-- Quanto cada carteira minerou de cada acao, por epoca. E isto que vira a raiz
-- de Merkle no fechamento.
-- Guarda DOLAR, nao quantidade de acao. A quantidade so e decidida no saque,
-- pela cotacao do momento. Guardar quantidade congelaria um preco antigo.
create table if not exists saldo_epoca (
  epoca     int not null,
  carteira  text not null,
  ticker    text not null,
  usd       numeric not null default 0,
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

-- Migracoes: "create table if not exists" nao adiciona coluna em tabela que ja
-- existe. Cada coluna nova entra aqui, de forma idempotente.
alter table jogador add column if not exists sessao_hash text;
alter table jogador add column if not exists sessao_expira timestamptz;
-- Batida do cliente: o servidor so minera o tempo em que a mina esteve ABERTA
-- na tela. Sem isto o jogo farmava com o navegador fechado, o que o G nao quer.
alter table mina add column if not exists visto_em timestamptz;
-- Teto DIARIO de producao por heroi. E o que impede um bot de ganhar mais que
-- quem joga: os dois batem no mesmo teto, o bot so chega la mais cedo.
-- O teto de energia sozinho nao resolve, porque a energia MAXIMA e stamina*50 e
-- enche em poucas horas: quem fecha a aba perde recarga, o bot captura tudo.
alter table heroi add column if not exists usd_dia numeric not null default 0;
alter table heroi add column if not exists dia_ref date;
-- Cotacao congelada no fechamento. Sem isto a quantidade era dolar dividido
-- pelo preco DO MOMENTO, e a raiz mudava a cada chamada mesmo com a epoca
-- fechada: 0xb9c995d4 virou 0xe09e9d78 em 35 segundos.
create table if not exists preco_epoca (
  epoca   int not null,
  ticker  text not null,
  preco   numeric not null,
  primary key (epoca, ticker)
);
