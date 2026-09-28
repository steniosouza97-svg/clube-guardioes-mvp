-- =====================================================================
-- Clube Guardiões do Começo | Instituto Ebenézer
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
    email               text not null unique check (email = lower(email)),
    cpf_hash            text not null unique check (cpf_hash ~ '^[0-9a-f]{64}$'),
                            -- CPF cifrado (HMAC-SHA256 com chave secreta). O número nunca é gravado.
    telefone            text,
    origem_id           smallint not null references origem (id),
    consentimento_lgpd  boolean not null check (consentimento_lgpd),
    consentimento_em    timestamptz not null default now(),
    entrou_em           date not null default current_date,
    id_externo_gateway  text unique,          -- id do cliente na Asaas (cus_...)
    criado_em           timestamptz not null default now()
);

-- Compromisso de doação mensal. Um Guardião tem no máximo uma assinatura ativa.
create table assinatura (
    id                   uuid primary key default gen_random_uuid(),
    guardiao_id          uuid not null references guardiao (id) on delete restrict,
    valor_mensal         numeric(10, 2) not null check (valor_mensal >= 10),
    dia_vencimento       smallint not null check (dia_vencimento between 1 and 28),
    meio_pagamento       text not null default 'pix'
                             check (meio_pagamento in ('pix', 'pix_direto', 'cartao', 'boleto')),
    status               text not null default 'ativa'
                             check (status in ('ativa', 'cancelada')),
    iniciada_em          date not null default current_date,
    cancelada_em         date,
    motivo_cancelamento  text check (motivo_cancelamento in ('voluntario', 'inadimplencia')),
    id_externo_gateway   text unique,         -- id da assinatura na Asaas (sub_...)
    check ((status = 'cancelada') = (cancelada_em is not null)),
    check ((status = 'cancelada') = (motivo_cancelamento is not null)),
    check (cancelada_em is null or cancelada_em >= iniciada_em)
);
create unique index ux_assinatura_ativa_por_guardiao
    on assinatura (guardiao_id) where status = 'ativa';

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
                     'impacto_mensal', 'cancelamento')),
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

comment on table parametro      is 'Parâmetros de negócio editáveis pelo Instituto.';
comment on table origem         is 'Canal de aquisição de cada Guardião.';
comment on table guardiao       is 'Doador recorrente. Cópia mínima do cliente na Asaas.';
comment on table assinatura     is 'Compromisso de doação mensal. Cópia da assinatura na Asaas.';
comment on table cobranca       is 'Cobrança mensal. Cópia da cobrança na Asaas.';
comment on table comunicacao    is 'Mensagens da régua de relacionamento.';
comment on table evento_gateway is 'Eventos de webhook já processados (idempotência).';
comment on table voluntario     is 'Pessoas autorizadas a operar o painel.';
