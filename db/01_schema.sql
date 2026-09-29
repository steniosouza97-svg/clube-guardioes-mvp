-- =====================================================================
-- Clube Guardiões do Futuro | Instituto Ebenézer
-- 01_schema.sql: modelo de dados do MVP
-- Compatível com PostgreSQL 15+ (Supabase) e PostgreSQL 16 local.
--
-- Regra de dados: a Asaas (gateway de pagamento) é a fonte da verdade.
-- Este banco guarda uma cópia mínima e reconstruível a partir dela.
-- Não armazenar dado de cartão. O CPF só é guardado cifrado (cpf_hash).
-- =====================================================================

-- Criptografia: pgcrypto (no Supabase já vem instalada no esquema extensions)
create schema if not exists extensions;
create extension if not exists pgcrypto with schema extensions;

-- Segredos do banco, fora do alcance da API: nenhum papel externo acessa este esquema.
-- A chave do CPF é gerada aleatoriamente na instalação e nunca sai do banco.
create schema if not exists privado;
revoke all on schema privado from public;
create table privado.segredo (
    chave  text primary key,
    valor  text not null
);
insert into privado.segredo (chave, valor)
values ('cpf_hmac', encode(extensions.gen_random_bytes(32), 'hex'));

-- Parâmetros de negócio editáveis pelo Instituto, sem mexer em código
create table parametro (
    chave      text primary key,
    valor      numeric not null,
    descricao  text not null
);

-- De onde veio cada Guardião: mede o resultado das ações de aquisição
create table origem (
    id        smallint generated always as identity primary key,
    nome      text not null unique,
    tipo      text not null check (tipo in (
                  'base_existente', 'doador_pontual', 'qr_code', 'instagram',
                  'whatsapp', 'indicacao', 'campanha', 'site')),
    ativa     boolean not null default true,
    criado_em timestamptz not null default now()
);

-- Pessoa que doa. Dado pessoal mínimo e consentimento LGPD obrigatório.
create table guardiao (
    id                  uuid primary key default gen_random_uuid(),
    nome                text not null check (length(trim(nome)) >= 2),
    email               text unique check (email = lower(email)),   -- opcional (decisão de 29/09)
    cpf_hash            text not null unique check (cpf_hash ~ '^[0-9a-f]{64}$'),
                            -- CPF cifrado (HMAC-SHA256 com chave secreta). O número nunca é gravado.
    telefone            text,
    origem_id           smallint not null references origem (id),
    consentimento_lgpd  boolean not null check (consentimento_lgpd),
    consentimento_em    timestamptz not null default now(),
    entrou_em           date not null default current_date,
    id_externo_gateway  text unique,          -- id do cliente na Asaas (cus_...)
    codigo_convite      text not null unique default substr(md5(gen_random_uuid()::text), 1, 8),
                            -- link pessoal de convite (?convite=...), jornada da semana 5
    indicado_por        uuid references guardiao (id),   -- quem convidou, se veio por convite
    convite_usado       text,                            -- código do link de quem convidou (Guardião ou doador de doação única)
    criado_em           timestamptz not null default now(),
    check (indicado_por is distinct from id)
);
create index ix_guardiao_indicado_por on guardiao (indicado_por);

-- Compromisso de doação mensal. Um Guardião tem no máximo uma assinatura ativa.
create table assinatura (
    id                   uuid primary key default gen_random_uuid(),
    guardiao_id          uuid not null references guardiao (id) on delete restrict,
    valor_mensal         numeric(10, 2) not null check (valor_mensal >= 10),
    dia_vencimento       smallint not null check (dia_vencimento between 1 and 28),
    meio_pagamento       text not null default 'pix'
                             check (meio_pagamento in ('pix', 'pix_direto', 'cartao', 'boleto')),
    status               text not null default 'ativa'
                             check (status in ('ativa', 'pausada', 'cancelada')),
    iniciada_em          date not null default current_date,
    pausada_ate          date,                -- primeiro mês em que a cobrança volta (pausa de 1 a 3 meses)
    cancelada_em         date,
    motivo_cancelamento  text check (motivo_cancelamento in ('voluntario', 'inadimplencia')),
    motivo_texto         text check (length(motivo_texto) <= 200),   -- motivo opcional dito pelo Guardião
    id_externo_gateway   text unique,         -- id da assinatura na Asaas (sub_...)
    check ((status = 'cancelada') = (cancelada_em is not null)),
    check ((status = 'cancelada') = (motivo_cancelamento is not null)),
    check ((status = 'pausada') = (pausada_ate is not null)),
    check (pausada_ate is null or pausada_ate = date_trunc('month', pausada_ate)::date),
    check (cancelada_em is null or cancelada_em >= iniciada_em)
);
-- Ativa ou pausada: o Guardião continua no Clube (a pausa evita a perda total)
create unique index ux_assinatura_ativa_por_guardiao
    on assinatura (guardiao_id) where status in ('ativa', 'pausada');

-- Cobrança de cada mês de uma assinatura
create table cobranca (
    id                  uuid primary key default gen_random_uuid(),
    assinatura_id       uuid not null references assinatura (id) on delete restrict,
    competencia         date not null check (competencia = date_trunc('month', competencia)::date),
    valor               numeric(10, 2) not null check (valor > 0),
    vencimento          date not null,
    status              text not null default 'pendente' check (status in (
                            'pendente', 'pago', 'falhou', 'recuperado', 'cancelado')),
    tentativas          smallint not null default 0 check (tentativas >= 0),
    pago_em             timestamptz,
    id_externo_gateway  text unique,          -- id da cobrança na Asaas (pay_...)
    unique (assinatura_id, competencia),
    check ((status in ('pago', 'recuperado')) = (pago_em is not null)),
    check (status <> 'recuperado' or tentativas >= 1)
);
create index ix_cobranca_status on cobranca (status);
create index ix_cobranca_competencia on cobranca (competencia);

-- Régua de relacionamento: toda mensagem enviada ao Guardião
create table comunicacao (
    id           bigint generated always as identity primary key,
    guardiao_id  uuid not null references guardiao (id) on delete restrict,
    cobranca_id  uuid references cobranca (id),
    competencia  date,
    tipo         text not null check (tipo in (
                     'boas_vindas', 'agradecimento', 'recuperacao',
                     'impacto_mensal', 'cancelamento', 'contato_pessoal',
                     'pausa', 'retomada', 'reativacao')),
    conteudo     text,                        -- texto da notícia de impacto ou anotação do contato
    canal        text not null default 'whatsapp' check (canal in ('whatsapp', 'email', 'sms')),
    enviada_em   timestamptz not null default now(),
    check (tipo <> 'impacto_mensal' or competencia is not null)
);
create unique index ux_impacto_mensal_unico
    on comunicacao (guardiao_id, competencia) where tipo = 'impacto_mensal';
create index ix_comunicacao_guardiao on comunicacao (guardiao_id);
create index ix_comunicacao_cobranca on comunicacao (cobranca_id);

-- Log de eventos recebidos do gateway. Garante idempotência do webhook:
-- o mesmo evento entregue duas vezes só produz efeito uma vez.
create table evento_gateway (
    id_evento    text primary key,
    tipo         text not null check (tipo in ('PAYMENT_RECEIVED', 'PAYMENT_OVERDUE')),
    cobranca_id  uuid not null references cobranca (id),
    recebido_em  timestamptz not null default now()
);
create index ix_evento_gateway_cobranca on evento_gateway (cobranca_id);
create index ix_guardiao_origem on guardiao (origem_id);

-- Quem opera o painel. Só e-mails desta lista (com login no Supabase)
-- enxergam dados de Guardiões e executam o fluxo. Criar conta não basta.
create table voluntario (
    email      text primary key check (email = lower(email)),
    nome       text not null,
    ativo      boolean not null default true,
    criado_em  timestamptz not null default now()
);

-- Atividades da rotina das crianças que a doação sustenta (jornada da semana 5).
-- A prestação de contas é sempre agregada por atividade, nunca por criança.
create table atividade (
    id         smallint generated always as identity primary key,
    nome       text not null unique,
    descricao  text,
    ativa      boolean not null default true
);

-- O que cada atividade sustentou no mês. A equipe registra antes de enviar a
-- notícia mensal de impacto; a notícia leva esses textos aos Guardiões.
create table impacto_mensal (
    atividade_id   smallint not null references atividade (id),
    competencia    date not null check (competencia = date_trunc('month', competencia)::date),
    texto          text not null check (length(trim(texto)) between 10 and 600),
    atualizado_em  timestamptz not null default now(),
    primary key (atividade_id, competencia)
);

-- Doação única (não recorrente), de qualquer valor. Para quem não pode ou
-- não quer ser Guardião mensal: ninguém fica de fora. Quem doa também
-- ganha um link pessoal para indicar novos doadores.
create table doacao_unica (
    id                  uuid primary key default gen_random_uuid(),
    nome                text not null check (length(trim(nome)) >= 2),
    email               text check (email = lower(email)),
    cpf_hash            text not null check (cpf_hash ~ '^[0-9a-f]{64}$'),
    telefone            text,
    valor               numeric(10, 2) not null check (valor between 10 and 50000),
    origem_id           smallint not null references origem (id),
    convite_usado       text,
    codigo_convite      text not null unique default substr(md5(gen_random_uuid()::text), 1, 8),
    status              text not null default 'pendente' check (status in ('pendente', 'paga', 'falhou')),
    consentimento_lgpd  boolean not null check (consentimento_lgpd),
    criada_em           timestamptz not null default now(),
    paga_em             timestamptz,
    id_externo_gateway  text unique,          -- id da cobrança avulsa na Asaas (pay_...)
    check ((status = 'paga') = (paga_em is not null))
);
create index ix_doacao_unica_cpf on doacao_unica (cpf_hash);
create index ix_doacao_unica_origem on doacao_unica (origem_id);

-- Tentativas de entrada na Minha Área (WhatsApp + CPF). Bloqueia depois de
-- 5 erros em 15 minutos para o mesmo WhatsApp (US06, critério 4). Guarda só
-- a impressão digital do WhatsApp, nunca o número.
create table tentativa_acesso (
    id             bigint generated always as identity primary key,
    telefone_hash  text not null,
    sucesso        boolean not null,
    em             timestamptz not null default now()
);
create index ix_tentativa_acesso on tentativa_acesso (telefone_hash, em);

comment on table parametro      is 'Parâmetros de negócio editáveis pelo Instituto.';
comment on table origem         is 'Canal de aquisição de cada Guardião.';
comment on table guardiao       is 'Doador recorrente. Cópia mínima do cliente na Asaas.';
comment on table assinatura     is 'Compromisso de doação mensal. Cópia da assinatura na Asaas.';
comment on table cobranca       is 'Cobrança mensal. Cópia da cobrança na Asaas.';
comment on table comunicacao    is 'Mensagens da régua de relacionamento.';
comment on table evento_gateway is 'Eventos de webhook já processados (idempotência).';
comment on table voluntario     is 'Pessoas autorizadas a operar o painel.';
comment on table atividade      is 'Atividades da rotina das crianças apoiadas pelo Clube.';
comment on table impacto_mensal is 'Prestação de contas mensal por atividade, enviada na notícia de impacto.';
comment on table doacao_unica   is 'Doação única (não recorrente), de qualquer valor.';
comment on table tentativa_acesso is 'Controle de tentativas de entrada na Minha Área.';
