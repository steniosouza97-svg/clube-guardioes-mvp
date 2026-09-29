-- =====================================================================
-- 02_funcoes.sql: o fluxo principal do Clube, implementado no banco
--
--   1. fn_aderir               adesão do Guardião
--   2. fn_gerar_cobrancas      cobrança mensal
--   3. fn_processar_evento     pagamento ou falha (espelha o webhook da Asaas)
--   4. fn_enviar_impacto_mensal mensagem mensal de impacto
--   5. fn_cancelar             cancelamento voluntário ou por inadimplência
--
-- No MVP, fn_processar_evento é chamada pela interface para simular o
-- gateway. Em produção, a mesma função é chamada pelo endpoint que recebe
-- o webhook da Asaas. A interface nunca guarda a chave de API.
-- =====================================================================

-- Quem está chamando pode operar o painel?
--   - conexão direta ao banco (SQL Editor, psql, testes): sim
--   - chamada da API com chave de serviço (webhook em produção): sim
--   - chamada da API com login: só se o e-mail estiver em voluntario
--   - visitante anônimo: não
create or replace function eh_voluntario() returns boolean
language sql stable security definer set search_path = public as $$
    select case
        when coalesce(current_setting('request.jwt.claims', true), '') = '' then true
        when (current_setting('request.jwt.claims', true)::jsonb ->> 'role') = 'service_role' then true
        else exists (select 1 from voluntario
                      where ativo
                        and email = lower(current_setting('request.jwt.claims', true)::jsonb ->> 'email'))
    end
$$;

create or replace function exigir_voluntario() returns void
language plpgsql stable set search_path = public as $$
begin
    if not eh_voluntario() then
        raise exception 'Acesso restrito aos voluntários cadastrados do Clube' using errcode = '42501';
    end if;
end;
$$;

-- ---------------------------------------------------------------- CPF
-- O CPF é o identificador único do Guardião (a Asaas também o exige).
-- O banco nunca grava o número: guarda só a impressão digital HMAC-SHA256
-- calculada com a chave secreta de privado.segredo. O mesmo CPF gera
-- sempre o mesmo código, o que permite barrar duplicidade, mas o código
-- não permite recuperar o número.

-- Dígitos verificadores a partir dos 9 primeiros dígitos
create or replace function fn_cpf_digitos(p_base text) returns text
language plpgsql immutable set search_path = public as $$
declare s int := 0; d1 int; d2 int; i int;
begin
    for i in 1..9 loop s := s + substr(p_base, i, 1)::int * (11 - i); end loop;
    d1 := case when s % 11 < 2 then 0 else 11 - s % 11 end;
    s := 0;
    for i in 1..9 loop s := s + substr(p_base, i, 1)::int * (12 - i); end loop;
    s := s + d1 * 2;
    d2 := case when s % 11 < 2 then 0 else 11 - s % 11 end;
    return d1::text || d2::text;
end;
$$;

-- CPF válido: 11 dígitos, não repetidos, dígitos verificadores corretos (aceita pontuação)
create or replace function fn_cpf_valido(p_cpf text) returns boolean
language plpgsql immutable set search_path = public as $$
declare d text := regexp_replace(coalesce(p_cpf, ''), '\D', '', 'g');
begin
    if d !~ '^[0-9]{11}$' or d ~ '^(\d)\1{10}$' then
        return false;
    end if;
    return right(d, 2) = fn_cpf_digitos(left(d, 9));
end;
$$;

-- Impressão digital do CPF. Só roda dentro do banco: nenhum papel externo a executa.
create or replace function fn_cpf_hash(p_cpf text) returns text
language plpgsql stable security definer set search_path = public as $$
declare v_chave text;
begin
    if not fn_cpf_valido(p_cpf) then
        raise exception 'CPF inválido: confira os números';
    end if;
    select valor into v_chave from privado.segredo where chave = 'cpf_hmac';
    if v_chave is null then
        raise exception 'Chave de cifragem do CPF não configurada';
    end if;
    return encode(extensions.hmac(regexp_replace(p_cpf, '\D', '', 'g'), v_chave, 'sha256'), 'hex');
end;
$$;

-- ---------------------------------------------------------------- adesão
create or replace function fn_aderir(
    p_nome          text,
    p_email         text,
    p_cpf           text,
    p_telefone      text,
    p_origem        text,
    p_valor         numeric,
    p_dia           smallint,
    p_meio          text    default 'pix',
    p_consentimento boolean default false,
    p_data          date    default current_date
) returns uuid
language plpgsql set search_path = public as $$
declare
    v_origem     smallint;
    v_guardiao   uuid;
    v_outro      uuid;
    v_assinatura uuid;
    v_email      text := nullif(lower(trim(coalesce(p_email, ''))), '');
    v_cpf_hash   text;
begin
    if not coalesce(p_consentimento, false) then
        raise exception 'Consentimento LGPD é obrigatório para aderir ao Clube';
    end if;
    -- E-mail é opcional (decisão de 29/09); se vier, precisa ser válido
    if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
        raise exception 'E-mail inválido: %', p_email;
    end if;
    -- Ambiente de demonstração: nenhum dado pessoal real (evento de 29/09, teste com e-mail real)
    if v_email is not null and v_email !~* '@example\.com$'
       and coalesce((select valor from parametro where chave = 'modo_demonstracao'), 0) = 1 then
        raise exception 'Ambiente de demonstração: use um e-mail terminado em @example.com ou deixe o e-mail em branco';
    end if;
    if not fn_cpf_valido(p_cpf) then
        raise exception 'CPF inválido: confira os números';
    end if;
    v_cpf_hash := fn_cpf_hash(p_cpf);

    select id into v_origem from origem where nome = p_origem and ativa;
    if v_origem is null then
        raise exception 'Origem desconhecida ou inativa: %', p_origem;
    end if;

    -- O CPF identifica a pessoa. O e-mail não pode pertencer a outro CPF.
    select id into v_guardiao from guardiao where cpf_hash = v_cpf_hash;
    if v_email is not null then
        select id into v_outro from guardiao where email = v_email;
    end if;
    if v_outro is not null and v_outro is distinct from v_guardiao then
        raise exception 'E-mail já cadastrado para outro CPF: %', v_email;
    end if;

    if v_guardiao is null then
        insert into guardiao (nome, email, cpf_hash, telefone, origem_id, consentimento_lgpd, entrou_em)
        values (trim(p_nome), v_email, v_cpf_hash, p_telefone, v_origem, true, p_data)
        returning id into v_guardiao;
    elsif exists (select 1 from assinatura where guardiao_id = v_guardiao and status in ('ativa', 'pausada')) then
        raise exception 'Este CPF já possui assinatura ativa no Clube';
    else
        -- ex-Guardião voltando: mantém o histórico e atualiza o contato
        update guardiao
           set email = coalesce(v_email, email), telefone = coalesce(p_telefone, telefone),
               consentimento_lgpd = true, consentimento_em = now()
         where id = v_guardiao;
    end if;

    insert into assinatura (guardiao_id, valor_mensal, dia_vencimento, meio_pagamento, iniciada_em)
    values (v_guardiao, p_valor, p_dia, p_meio, p_data)
    returning id into v_assinatura;

    insert into comunicacao (guardiao_id, tipo, enviada_em)
    values (v_guardiao, 'boas_vindas', p_data::timestamptz);

    return v_assinatura;
end;
$$;

-- Consulta do voluntário: este CPF já é Guardião? Responde sem revelar o número.
create or replace function fn_consultar_cpf(p_cpf text)
returns table (nome text, email text, situacao text, valor_mensal numeric, origem text)
language plpgsql stable security definer set search_path = public as $$
begin
    perform exigir_voluntario();
    return query
        select v.nome, v.email, v.situacao, v.valor_mensal, v.origem
          from vw_situacao_guardiao v
          join guardiao g on g.id = v.guardiao_id
         where g.cpf_hash = fn_cpf_hash(p_cpf);
end;
$$;

create or replace function fn_gerar_cobrancas(p_competencia date)
returns integer
language plpgsql as $$
declare
    v_comp date := date_trunc('month', p_competencia)::date;
    v_qtd  integer;
begin
    perform exigir_voluntario();
    -- Pausas que terminam nesta competência: a doação volta sozinha
    with retomadas as (
        update assinatura set status = 'ativa', pausada_ate = null
         where status = 'pausada' and pausada_ate <= v_comp
        returning guardiao_id)
    insert into comunicacao (guardiao_id, competencia, tipo, enviada_em)
    select guardiao_id, v_comp, 'retomada', v_comp::timestamptz from retomadas;

    insert into cobranca (assinatura_id, competencia, valor, vencimento)
    select a.id,
           v_comp,
           a.valor_mensal,
           make_date(extract(year from v_comp)::int, extract(month from v_comp)::int, a.dia_vencimento)
      from assinatura a
     where a.status = 'ativa'
       and a.iniciada_em < (v_comp + interval '1 month')
    on conflict (assinatura_id, competencia) do nothing;
    get diagnostics v_qtd = row_count;
    return v_qtd;
end;
$$;

create or replace function fn_cancelar(
    p_assinatura uuid,
    p_motivo     text,
    p_data       date default current_date
) returns void
language plpgsql as $$
declare
    v_guardiao uuid;
begin
    perform exigir_voluntario();
    update assinatura
       set status = 'cancelada', cancelada_em = greatest(p_data, iniciada_em), motivo_cancelamento = p_motivo,
           pausada_ate = null
     where id = p_assinatura and status in ('ativa', 'pausada')
    returning guardiao_id into v_guardiao;
    if v_guardiao is null then
        raise exception 'Assinatura % não encontrada ou já cancelada', p_assinatura;
    end if;

    update cobranca set status = 'cancelado'
     where assinatura_id = p_assinatura and status = 'pendente';

    insert into comunicacao (guardiao_id, tipo, enviada_em)
    values (v_guardiao, 'cancelamento', p_data::timestamptz);
end;
$$;

create or replace function fn_processar_evento(
    p_id_evento text,
    p_cobranca  uuid,
    p_tipo      text,
    p_quando    timestamptz default now()
) returns text
language plpgsql as $$
declare
    v_cob        cobranca%rowtype;
    v_guardiao   uuid;
    v_novo       text;
    v_tentativas smallint;
    v_limite     smallint := coalesce((select valor from parametro where chave = 'tentativas_ate_cancelar'), 3);
begin
    perform exigir_voluntario();
    insert into evento_gateway (id_evento, tipo, cobranca_id, recebido_em)
    values (p_id_evento, p_tipo, p_cobranca, p_quando)
    on conflict (id_evento) do nothing;
    if not found then
        return 'duplicado';
    end if;

    select * into v_cob from cobranca where id = p_cobranca for update;
    if not found then
        raise exception 'Cobrança % não encontrada', p_cobranca;
    end if;
    select guardiao_id into v_guardiao from assinatura where id = v_cob.assinatura_id;

    if p_tipo = 'PAYMENT_RECEIVED' then
        if v_cob.status in ('pago', 'recuperado') then
            return 'ja_pago';
        elsif v_cob.status = 'cancelado' then
            raise exception 'Pagamento recebido para cobrança cancelada %', p_cobranca;
        end if;
        v_novo := case when v_cob.status = 'falhou' then 'recuperado' else 'pago' end;
        update cobranca set status = v_novo, pago_em = p_quando where id = p_cobranca;
        insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo, enviada_em)
        values (v_guardiao, p_cobranca, v_cob.competencia, 'agradecimento', p_quando);
        return v_novo;

    elsif p_tipo = 'PAYMENT_OVERDUE' then
        -- cobrança já resolvida, ou assinatura já encerrada: não há o que recuperar
        if v_cob.status not in ('pendente', 'falhou')
           or exists (select 1 from assinatura where id = v_cob.assinatura_id and status = 'cancelada') then
            return 'ignorado';
        end if;
        update cobranca set status = 'falhou', tentativas = tentativas + 1
         where id = p_cobranca
        returning tentativas into v_tentativas;
        insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo, enviada_em)
        values (v_guardiao, p_cobranca, v_cob.competencia, 'recuperacao', p_quando);
        if v_tentativas >= v_limite then
            perform fn_cancelar(v_cob.assinatura_id, 'inadimplencia', p_quando::date);
            return 'cancelado_por_inadimplencia';
        end if;
        return 'falhou';
    end if;

    raise exception 'Tipo de evento não suportado: %', p_tipo;
end;
$$;

create or replace function fn_enviar_impacto_mensal(p_competencia date, p_quando timestamptz default now())
returns integer
language plpgsql as $$
declare
    v_comp     date := date_trunc('month', p_competencia)::date;
    v_qtd      integer;
    v_conteudo text;
begin
    perform exigir_voluntario();
    -- A notícia leva a prestação de contas por atividade registrada pela equipe
    select string_agg(at.nome || ': ' || im.texto, E'\n' order by at.nome)
      into v_conteudo
      from impacto_mensal im join atividade at on at.id = im.atividade_id
     where im.competencia = v_comp;
    if v_conteudo is null then
        raise exception 'Registre em Atividades o que o mês sustentou antes de enviar a notícia de impacto';
    end if;
    insert into comunicacao (guardiao_id, competencia, tipo, enviada_em, conteudo)
    select a.guardiao_id, v_comp, 'impacto_mensal', p_quando, v_conteudo
      from assinatura a
     where a.status in ('ativa', 'pausada')
    on conflict (guardiao_id, competencia) where tipo = 'impacto_mensal' do nothing;
    get diagnostics v_qtd = row_count;
    return v_qtd;
end;
$$;

-- =====================================================================
-- Funções usadas pela interface do MVP
-- =====================================================================

-- Adesão pela página pública do Clube. É a única função que o visitante
-- anônimo pode chamar. Fixa o meio de pagamento em Pix e a data de hoje,
-- limita o valor e não devolve identificadores internos.
-- Em produção, a adesão acontece no checkout da Asaas e esta função é
-- substituída pelo registro do cliente vindo do webhook.
create or replace function fn_aderir_publico(
    p_nome          text,
    p_email         text,
    p_cpf           text,
    p_telefone      text,
    p_origem        text,
    p_valor         numeric,
    p_dia           smallint,
    p_consentimento boolean,
    p_convite       text default null      -- código do link pessoal de quem convidou
) returns jsonb
language plpgsql as $$
declare
    v_assinatura uuid;
    v_guardiao   uuid;
    v_padrinho   uuid;
    v_convite    text;
    v_origem     text := coalesce(p_origem, 'Site institucional');
    v_valor      numeric := (select valor from parametro where chave = 'valor_guardiao');
begin
    -- O Guardião doa R$ 85 por mês (decisão de 29/09). Outros valores
    -- entram como doação única (fn_doar_unica), sem deixar ninguém de fora.
    if p_valor is distinct from v_valor then
        raise exception 'A doação mensal do Guardião é de R$ %. Para outro valor, faça uma doação única.',
                        replace(to_char(v_valor, 'FM999990'), '.', ',');
    end if;
    if length(coalesce(p_nome, '')) > 120 or length(coalesce(p_telefone, '')) > 30 then
        raise exception 'Dados de contato inválidos';
    end if;
    -- Convite válido: link pessoal de um Guardião do Clube ou de quem fez doação única
    v_convite := fn_convite_valido(p_convite);
    if v_convite is not null then
        v_origem := 'Indicação de Guardião';
        select id into v_padrinho from guardiao where codigo_convite = v_convite;
    end if;

    v_assinatura := fn_aderir(p_nome, p_email, p_cpf, p_telefone, v_origem,
                              v_valor, p_dia, 'pix', p_consentimento, current_date);
    select guardiao_id into v_guardiao from assinatura where id = v_assinatura;

    if v_convite is not null then
        update guardiao
           set convite_usado = coalesce(convite_usado, v_convite),
               indicado_por  = coalesce(indicado_por, case when v_padrinho <> v_guardiao then v_padrinho end)
         where id = v_guardiao
           and v_convite <> codigo_convite;
    end if;

    -- Devolve só o necessário para as telas seguintes (Pix, confirmação, convite)
    return jsonb_build_object(
        'primeiro_nome',  split_part(trim(p_nome), ' ', 1),
        'valor',          v_valor,
        'dia',            p_dia,
        'codigo_convite', (select codigo_convite from guardiao where id = v_guardiao),
        'convidado_por',  fn_convite_nome(v_convite));
end;
$$;

-- Código de convite válido: de um Guardião do Clube (ativo ou pausado) ou de
-- uma doação única paga. Devolve o código normalizado, ou nulo.
create or replace function fn_convite_valido(p_codigo text)
returns text
language sql stable set search_path = public as $$
    select c from (select lower(trim(p_codigo)) as c) x
     where nullif(c, '') is not null
       and (exists (select 1 from guardiao g
                     where g.codigo_convite = c
                       and exists (select 1 from assinatura a
                                    where a.guardiao_id = g.id and a.status in ('ativa', 'pausada')))
            or exists (select 1 from doacao_unica d where d.codigo_convite = c and d.status = 'paga'));
$$;

-- Nome de quem convidou, para a faixa "Você foi convidado(a) por..." da página.
-- Devolve só o primeiro nome.
create or replace function fn_convite_nome(p_codigo text)
returns text
language sql stable set search_path = public as $$
    select coalesce(
        (select split_part(g.nome, ' ', 1) from guardiao g where g.codigo_convite = fn_convite_valido(p_codigo)),
        (select split_part(d.nome, ' ', 1) from doacao_unica d where d.codigo_convite = fn_convite_valido(p_codigo)));
$$;

-- A equipe registra o que cada atividade sustentou no mês (tela Atividades).
create or replace function fn_salvar_impacto(p_atividade smallint, p_competencia date, p_texto text)
returns void
language plpgsql as $$
declare
    v_comp date := date_trunc('month', p_competencia)::date;
begin
    perform exigir_voluntario();
    if not exists (select 1 from atividade where id = p_atividade and ativa) then
        raise exception 'Atividade % não encontrada ou inativa', p_atividade;
    end if;
    if length(trim(coalesce(p_texto, ''))) < 10 then
        raise exception 'Descreva o que a atividade sustentou no mês (mínimo de 10 caracteres)';
    end if;
    insert into impacto_mensal (atividade_id, competencia, texto, atualizado_em)
    values (p_atividade, v_comp, trim(p_texto), now())
    on conflict (atividade_id, competencia)
    do update set texto = excluded.texto, atualizado_em = now();
end;
$$;

-- Contato pessoal feito pela equipe com um Guardião (alerta de churn).
create or replace function fn_registrar_contato(p_guardiao uuid, p_anotacao text default null)
returns void
language plpgsql as $$
begin
    perform exigir_voluntario();
    if not exists (select 1 from guardiao where id = p_guardiao) then
        raise exception 'Guardião % não encontrado', p_guardiao;
    end if;
    insert into comunicacao (guardiao_id, tipo, conteudo)
    values (p_guardiao, 'contato_pessoal', nullif(trim(coalesce(p_anotacao, '')), ''));
end;
$$;

-- SIMULADOR DO GATEWAY (somente MVP). Faz o papel da Asaas na
-- demonstração: para cada cobrança em aberto da competência, emite o
-- evento que a Asaas emitiria e o entrega a fn_processar_evento, o mesmo
-- caminho que o webhook real usará.
--   pendente -> PAYMENT_RECEIVED (com probabilidade p_taxa_pagamento)
--               ou PAYMENT_OVERDUE
--   falhou   -> PAYMENT_RECEIVED (com probabilidade p_taxa_recuperacao)
--               ou nova PAYMENT_OVERDUE (nova tentativa)
create or replace function fn_simular_gateway(
    p_competencia      date,
    p_taxa_pagamento   numeric     default 0.91,
    p_taxa_recuperacao numeric     default 0.60,
    p_quando           timestamptz default now()
) returns jsonb
language plpgsql as $$
declare
    v_comp date := date_trunc('month', p_competencia)::date;
    c      record;
    r      text;
    v_res  jsonb := '{}'::jsonb;
begin
    perform exigir_voluntario();
    for c in select cb.id, cb.status from cobranca cb
               join assinatura a on a.id = cb.assinatura_id and a.status = 'ativa'
              where cb.competencia = v_comp and cb.status in ('pendente', 'falhou')
                and a.meio_pagamento <> 'pix_direto'   -- a Asaas não vê o Pix direto
              order by cb.vencimento, cb.id loop
        r := fn_processar_evento(
                 'evt_sim_' || replace(gen_random_uuid()::text, '-', ''),
                 c.id,
                 case when random() < (case when c.status = 'pendente' then p_taxa_pagamento
                                            else p_taxa_recuperacao end)
                      then 'PAYMENT_RECEIVED' else 'PAYMENT_OVERDUE' end,
                 p_quando);
        v_res := jsonb_set(v_res, array[r], to_jsonb(coalesce((v_res ->> r)::int, 0) + 1));
    end loop;
    return v_res;
end;
$$;

-- MODELO HÍBRIDO DA BASE ATUAL. Os Guardiões que já doam por Pix direto na
-- conta do Instituto entram no painel desde o primeiro dia, com CPF e
-- consentimento, sem trocar a forma de pagar. A pessoa dedicada os convida
-- a migrar para a Asaas; quem não migrar tem o Pix conferido no extrato e
-- registrado à mão. Assim toda a base recebe a mesma comunicação e aparece
-- nas mesmas métricas.
create or replace function fn_cadastrar_pix_direto(
    p_nome          text,
    p_email         text,
    p_cpf           text,
    p_telefone      text,
    p_valor         numeric,
    p_dia           smallint,
    p_consentimento boolean,
    p_data          date default current_date
) returns uuid
language plpgsql as $$
begin
    perform exigir_voluntario();
    if p_valor is null or p_valor < 10 or p_valor > 5000 then
        raise exception 'Valor mensal deve estar entre R$ 10 e R$ 5.000';
    end if;
    return fn_aderir(p_nome, p_email, p_cpf, p_telefone, 'Base Pix manual',
                     p_valor, p_dia, 'pix_direto', p_consentimento, p_data);
end;
$$;

-- Registro manual do Pix direto, conferido no extrato bancário. Usa o mesmo
-- caminho do webhook (fn_processar_evento), com identificador "manual_":
-- agradecimento, lembrete, alerta de churn e inadimplência funcionam igual.
create or replace function fn_registrar_pix_direto(
    p_cobranca uuid,
    p_recebido boolean,
    p_quando   timestamptz default now()
) returns text
language plpgsql as $$
declare
    v_meio text;
begin
    perform exigir_voluntario();
    select a.meio_pagamento into v_meio
      from cobranca c join assinatura a on a.id = c.assinatura_id
     where c.id = p_cobranca;
    if v_meio is null then
        raise exception 'Cobrança % não encontrada', p_cobranca;
    elsif v_meio <> 'pix_direto' then
        raise exception 'Cobrança da Asaas: o pagamento é registrado pelo aviso do gateway, não à mão';
    end if;
    return fn_processar_evento('manual_' || replace(gen_random_uuid()::text, '-', ''), p_cobranca,
                               case when p_recebido then 'PAYMENT_RECEIVED' else 'PAYMENT_OVERDUE' end, p_quando);
end;
$$;

-- Migração para a Asaas, depois do aceite do Guardião. Mantém valor, dia e
-- histórico; a partir daí a cobrança chega pela Asaas e a régua é automática.
create or replace function fn_migrar_para_asaas(p_assinatura uuid)
returns void
language plpgsql as $$
begin
    perform exigir_voluntario();
    update assinatura set meio_pagamento = 'pix'
     where id = p_assinatura and status = 'ativa' and meio_pagamento = 'pix_direto';
    if not found then
        raise exception 'Assinatura % não está ativa em Pix direto', p_assinatura;
    end if;
end;
$$;

-- =====================================================================
-- Decisões de 29/09: doação única de qualquer valor, pausa da doação
-- mensal, Minha Área do Guardião e gamificação por estrelas
-- =====================================================================

-- DOAÇÃO ÚNICA. Para quem não pode doar R$ 85 por mês, ou quer doar mais
-- sem ser recorrente. Chamável pelo visitante anônimo. Quem doa também
-- ganha um link pessoal para indicar novos doadores.
-- Em produção, a cobrança avulsa é criada na Asaas e o webhook confirma.
create or replace function fn_doar_unica(
    p_nome          text,
    p_email         text,
    p_cpf           text,
    p_telefone      text,
    p_origem        text,
    p_valor         numeric,
    p_consentimento boolean,
    p_convite       text default null
) returns jsonb
language plpgsql as $$
declare
    v_email   text := nullif(lower(trim(coalesce(p_email, ''))), '');
    v_origem  smallint;
    v_convite text := fn_convite_valido(p_convite);
    v_codigo  text;
begin
    if not coalesce(p_consentimento, false) then
        raise exception 'Consentimento LGPD é obrigatório para doar';
    end if;
    if p_valor is null or p_valor < 10 or p_valor > 50000 then
        raise exception 'Valor da doação deve estar entre R$ 10 e R$ 50.000';
    end if;
    if length(trim(coalesce(p_nome, ''))) < 2 or length(p_nome) > 120 or length(coalesce(p_telefone, '')) > 30 then
        raise exception 'Dados de contato inválidos';
    end if;
    if v_email is not null and v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
        raise exception 'E-mail inválido: %', p_email;
    end if;
    -- Ambiente de demonstração: nenhum dado pessoal real (evento de 29/09, teste com e-mail real)
    if v_email is not null and v_email !~* '@example\.com$'
       and coalesce((select valor from parametro where chave = 'modo_demonstracao'), 0) = 1 then
        raise exception 'Ambiente de demonstração: use um e-mail terminado em @example.com ou deixe o e-mail em branco';
    end if;
    if not fn_cpf_valido(p_cpf) then
        raise exception 'CPF inválido: confira os números';
    end if;
    select id into v_origem from origem
     where nome = case when v_convite is not null then 'Indicação de Guardião'
                       else coalesce(p_origem, 'Site institucional') end
       and ativa;
    if v_origem is null then
        raise exception 'Origem desconhecida ou inativa: %', p_origem;
    end if;

    insert into doacao_unica (nome, email, cpf_hash, telefone, valor, origem_id, convite_usado, consentimento_lgpd)
    values (trim(p_nome), v_email, fn_cpf_hash(p_cpf), p_telefone, p_valor, v_origem, v_convite, true)
    returning codigo_convite into v_codigo;

    return jsonb_build_object(
        'primeiro_nome',  split_part(trim(p_nome), ' ', 1),
        'valor',          p_valor,
        'codigo_convite', v_codigo,
        'convidado_por',  fn_convite_nome(v_convite));
end;
$$;

-- "Já paguei" da doação única na DEMONSTRAÇÃO. Em produção quem confirma é o
-- webhook da Asaas; com parametro.modo_demonstracao = 0 esta função recusa.
create or replace function fn_confirmar_doacao_demo(p_codigo text)
returns text
language plpgsql as $$
begin
    if coalesce((select valor from parametro where chave = 'modo_demonstracao'), 0) <> 1 then
        raise exception 'Confirmação manual desativada: em produção a Asaas confirma o Pix';
    end if;
    update doacao_unica set status = 'paga', paga_em = now()
     where codigo_convite = lower(trim(p_codigo)) and status in ('pendente', 'falhou');
    if not found then
        return 'nada_a_confirmar';
    end if;
    return 'paga';
end;
$$;

-- Aviso de pagamento da doação única (caminho do webhook; voluntário no MVP)
create or replace function fn_processar_doacao_unica(p_codigo text, p_tipo text, p_quando timestamptz default now())
returns text
language plpgsql as $$
begin
    perform exigir_voluntario();
    if p_tipo = 'PAYMENT_RECEIVED' then
        update doacao_unica set status = 'paga', paga_em = p_quando
         where codigo_convite = p_codigo and status <> 'paga';
        return case when found then 'paga' else 'ja_paga' end;
    elsif p_tipo = 'PAYMENT_OVERDUE' then
        update doacao_unica set status = 'falhou' where codigo_convite = p_codigo and status = 'pendente';
        return case when found then 'falhou' else 'ignorado' end;
    end if;
    raise exception 'Tipo de evento não suportado: %', p_tipo;
end;
$$;

-- PAUSA DA DOAÇÃO MENSAL (1 a 3 meses). Evita a perda total do Guardião:
-- as cobranças em aberto a partir do mês da pausa são canceladas e a
-- doação volta sozinha no mês indicado (fn_gerar_cobrancas retoma).
create or replace function fn_pausar_interno(p_assinatura uuid, p_meses integer, p_data date)
returns date
language plpgsql set search_path = public as $$
declare
    v_max    integer := coalesce((select valor from parametro where chave = 'pausa_maxima_meses'), 3);
    v_mes    date := date_trunc('month', p_data)::date;
    v_inicio date;
    v_volta  date;
    v_g      uuid;
begin
    if p_meses is null or p_meses < 1 or p_meses > v_max then
        raise exception 'A pausa é de 1 a % meses', v_max;
    end if;
    select guardiao_id into v_g from assinatura where id = p_assinatura and status = 'ativa' for update;
    if v_g is null then
        raise exception 'Só uma doação mensal ativa pode ser pausada';
    end if;
    -- o mês corrente já pago conta; a pausa começa no primeiro mês ainda não pago
    v_inicio := case when exists (select 1 from cobranca where assinatura_id = p_assinatura and competencia = v_mes
                                     and status in ('pago', 'recuperado'))
                     then (v_mes + interval '1 month')::date else v_mes end;
    v_volta := (v_inicio + make_interval(months => p_meses))::date;
    update assinatura set status = 'pausada', pausada_ate = v_volta where id = p_assinatura;
    update cobranca set status = 'cancelado'
     where assinatura_id = p_assinatura and competencia >= v_inicio and status in ('pendente', 'falhou');
    insert into comunicacao (guardiao_id, tipo, enviada_em, conteudo)
    values (v_g, 'pausa', p_data::timestamptz, format('Pausa de %s mês(es); volta em %s', p_meses, to_char(v_volta, 'MM/YYYY')));
    return v_volta;
end;
$$;

create or replace function fn_retomar_interno(p_assinatura uuid, p_data date)
returns void
language plpgsql set search_path = public as $$
declare
    v_g uuid;
begin
    update assinatura set status = 'ativa', pausada_ate = null
     where id = p_assinatura and status = 'pausada'
    returning guardiao_id into v_g;
    if v_g is null then
        raise exception 'Esta doação não está pausada';
    end if;
    insert into comunicacao (guardiao_id, tipo, enviada_em) values (v_g, 'retomada', p_data::timestamptz);
end;
$$;

-- Versões do painel (voluntário, a pedido do Guardião)
create or replace function fn_pausar(p_assinatura uuid, p_meses integer, p_data date default current_date)
returns date
language plpgsql as $$
begin
    perform exigir_voluntario();
    return fn_pausar_interno(p_assinatura, p_meses, p_data);
end;
$$;

create or replace function fn_retomar(p_assinatura uuid, p_data date default current_date)
returns void
language plpgsql as $$
begin
    perform exigir_voluntario();
    perform fn_retomar_interno(p_assinatura, p_data);
end;
$$;

-- GAMIFICAÇÃO. 1ª estrela na primeira doação paga e mais uma a cada 3 meses (teto de 5).
-- 3 estrelas: Guardião Bronze; 4: Prata; 5 ou mais: Ouro.
create or replace function fn_nivel(p_estrelas integer)
returns text
language sql immutable as $$
    select case when p_estrelas >= 5 then 'Guardião Ouro'
                when p_estrelas = 4  then 'Guardião Prata'
                when p_estrelas = 3  then 'Guardião Bronze'
                else 'Guardião' end;
$$;

-- MINHA ÁREA DO GUARDIÃO (protótipo da semana 5). Entrada por WhatsApp + CPF,
-- como no protótipo. Não devolve e-mail, telefone nem CPF. Bloqueia após 5
-- tentativas erradas em 15 minutos. O login por código de verificação (US06)
-- é o passo antes de operar com doadores reais.
create or replace function fn_area_autenticar(p_telefone text, p_cpf text)
returns uuid
language plpgsql set search_path = public as $$
declare
    v_tel  text := regexp_replace(coalesce(p_telefone, ''), '\D', '', 'g');
    v_hash text;
    v_g    uuid;
begin
    if length(v_tel) in (12, 13) and v_tel like '55%' then
        v_tel := substr(v_tel, 3);
    end if;
    if length(v_tel) < 10 then
        return null;
    end if;
    -- impressão digital do WhatsApp (HMAC com a mesma chave secreta do CPF)
    v_hash := encode(extensions.hmac(v_tel, (select valor from privado.segredo where chave = 'cpf_hmac'), 'sha256'), 'hex');
    if (select count(*) from tentativa_acesso
         where telefone_hash = v_hash and not sucesso and em > now() - interval '15 minutes') >= 5 then
        raise exception 'Muitas tentativas. Aguarde 15 minutos e tente de novo.';
    end if;
    if fn_cpf_valido(p_cpf) then
        select g.id into v_g from guardiao g
         where g.cpf_hash = fn_cpf_hash(p_cpf)
           and regexp_replace(coalesce(g.telefone, ''), '\D', '', 'g') in (v_tel, '55' || v_tel);
    end if;
    insert into tentativa_acesso (telefone_hash, sucesso) values (v_hash, v_g is not null);
    return v_g;
end;
$$;

create or replace function fn_area_dados(p_guardiao uuid)
returns jsonb
language plpgsql stable set search_path = public as $$
declare
    g   guardiao%rowtype;
    a   assinatura%rowtype;
    v_pagos    integer;
    v_estrelas integer;
    v_meses_estrela integer := coalesce((select valor from parametro where chave = 'meses_por_estrela'), 3);
    v_proxima  date;
    v_hoje     date := current_date;
begin
    select * into g from guardiao where id = p_guardiao;
    select * into a from assinatura where guardiao_id = p_guardiao
     order by (status in ('ativa', 'pausada')) desc, iniciada_em desc limit 1;
    select count(*) into v_pagos
      from cobranca c join assinatura x on x.id = c.assinatura_id
     where x.guardiao_id = p_guardiao and c.status in ('pago', 'recuperado');
    -- 1ª estrela na primeira doação paga; depois, uma a cada v_meses_estrela meses (decisão de 29/09, tarde)
    v_estrelas := case when v_pagos = 0 then 0 else least(5, 1 + v_pagos / v_meses_estrela) end;
    if a.status = 'ativa' then
        v_proxima := make_date(extract(year from v_hoje)::int, extract(month from v_hoje)::int, a.dia_vencimento);
        if v_proxima < v_hoje or exists (select 1 from cobranca c where c.assinatura_id = a.id
                                            and c.competencia = date_trunc('month', v_hoje)::date
                                            and c.status in ('pago', 'recuperado', 'cancelado')) then
            v_proxima := (make_date(extract(year from v_hoje)::int, extract(month from v_hoje)::int, 1)
                          + interval '1 month' + make_interval(days => a.dia_vencimento - 1))::date;
        end if;
    elsif a.status = 'pausada' then
        v_proxima := (a.pausada_ate + make_interval(days => a.dia_vencimento - 1))::date;
    end if;
    return jsonb_build_object(
        'primeiro_nome', split_part(g.nome, ' ', 1),
        'desde',         g.entrou_em,
        'status',        case when a.id is null then 'sem_assinatura'
                              when a.status = 'ativa' and exists (select 1 from cobranca c where c.assinatura_id = a.id and c.status = 'falhou')
                                   then 'atrasada'
                              else a.status end,
        'valor',         a.valor_mensal,
        'dia',           a.dia_vencimento,
        'meio',          a.meio_pagamento,
        'pausada_ate',   a.pausada_ate,
        'proxima',       v_proxima,
        'meses_pagos',   v_pagos,
        'total_doado',   (select coalesce(sum(c.valor), 0) from cobranca c join assinatura x on x.id = c.assinatura_id
                           where x.guardiao_id = p_guardiao and c.status in ('pago', 'recuperado')),
        'estrelas',      v_estrelas,
        'nivel',         fn_nivel(v_estrelas),
        'meses_para_proxima_estrela', case when v_pagos = 0 then 1 else v_meses_estrela - (v_pagos % v_meses_estrela) end,
        'codigo_convite', g.codigo_convite,
        'indicacoes',    (select count(*) from guardiao x where x.convite_usado = g.codigo_convite)
                       + (select count(*) from doacao_unica d where d.convite_usado = g.codigo_convite),
        'atraso',        (select jsonb_build_object('competencia', c.competencia, 'valor', c.valor, 'vencimento', c.vencimento)
                            from cobranca c where c.assinatura_id = a.id and c.status = 'falhou'
                           order by c.competencia limit 1),
        'historico',     coalesce((select jsonb_agg(jsonb_build_object('competencia', c.competencia, 'valor', c.valor,
                                                                        'status', c.status, 'pago_em', c.pago_em)
                                                     order by c.competencia desc)
                                     from (select c.* from cobranca c join assinatura x on x.id = c.assinatura_id
                                            where x.guardiao_id = p_guardiao
                                            order by c.competencia desc limit 24) c), '[]'::jsonb),
        'impacto',       coalesce((select jsonb_agg(jsonb_build_object('competencia', m.competencia, 'texto', m.conteudo)
                                                     order by m.competencia desc)
                                     from (select * from comunicacao m
                                            where m.guardiao_id = p_guardiao and m.tipo = 'impacto_mensal'
                                            order by m.competencia desc limit 12) m), '[]'::jsonb));
end;
$$;

-- Entrada na Minha Área. Devolve os dados ou {erro: ...}.
create or replace function fn_area(p_telefone text, p_cpf text)
returns jsonb
language plpgsql as $$
declare
    v_g uuid := fn_area_autenticar(p_telefone, p_cpf);
begin
    if v_g is null then
        return jsonb_build_object('erro', 'Não encontramos um Guardião com esse WhatsApp e CPF.');
    end if;
    return fn_area_dados(v_g);
end;
$$;

-- Ações do próprio Guardião na Minha Área: pausar, retomar, cancelar,
-- reativar e, na demonstração, regularizar o Pix em atraso.
create or replace function fn_area_acao(
    p_telefone text,
    p_cpf      text,
    p_acao     text,
    p_meses    integer default null,
    p_motivo   text    default null
) returns jsonb
language plpgsql as $$
declare
    v_g   uuid := fn_area_autenticar(p_telefone, p_cpf);
    a     assinatura%rowtype;
    v_cob uuid;
begin
    if v_g is null then
        return jsonb_build_object('erro', 'Sessão inválida. Entre de novo com WhatsApp e CPF.');
    end if;
    select * into a from assinatura where guardiao_id = v_g
     order by (status in ('ativa', 'pausada')) desc, iniciada_em desc limit 1;

    if p_acao = 'pausar' then
        perform fn_pausar_interno(a.id, p_meses, current_date);
    elsif p_acao = 'retomar' then
        perform fn_retomar_interno(a.id, current_date);
    elsif p_acao = 'cancelar' then
        if a.status not in ('ativa', 'pausada') then
            raise exception 'Não há doação mensal ativa para cancelar';
        end if;
        update assinatura set status = 'cancelada', cancelada_em = greatest(current_date, iniciada_em),
                              motivo_cancelamento = 'voluntario', pausada_ate = null,
                              motivo_texto = nullif(left(trim(coalesce(p_motivo, '')), 200), '')
         where id = a.id;
        update cobranca set status = 'cancelado' where assinatura_id = a.id and status = 'pendente';
        insert into comunicacao (guardiao_id, tipo, conteudo) values (v_g, 'cancelamento', nullif(trim(coalesce(p_motivo, '')), ''));
    elsif p_acao = 'reativar' then
        if a.status in ('ativa', 'pausada') then
            raise exception 'Sua doação mensal já está ativa';
        end if;
        insert into assinatura (guardiao_id, valor_mensal, dia_vencimento, meio_pagamento, iniciada_em)
        values (v_g, (select valor from parametro where chave = 'valor_guardiao'),
                coalesce(a.dia_vencimento, 10), 'pix', current_date);
        insert into comunicacao (guardiao_id, tipo) values (v_g, 'reativacao');
    elsif p_acao = 'regularizar' then
        if coalesce((select valor from parametro where chave = 'modo_demonstracao'), 0) <> 1 then
            raise exception 'Em produção, o Pix em atraso é confirmado pela Asaas';
        end if;
        select c.id into v_cob from cobranca c where c.assinatura_id = a.id and c.status = 'falhou'
         order by c.competencia limit 1;
        if v_cob is null then
            raise exception 'Não há Pix em atraso';
        end if;
        -- mesmo caminho do webhook, marcado como demonstração
        insert into evento_gateway (id_evento, tipo, cobranca_id)
        values ('evt_area_' || replace(gen_random_uuid()::text, '-', ''), 'PAYMENT_RECEIVED', v_cob);
        update cobranca set status = 'recuperado', pago_em = now() where id = v_cob;
        insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo)
        select v_g, v_cob, competencia, 'agradecimento' from cobranca where id = v_cob;
    else
        raise exception 'Ação desconhecida: %', p_acao;
    end if;
    return fn_area_dados(v_g);
end;
$$;

-- Recibo anual das doações do Guardião (mensais e únicas, com o mesmo CPF)
create or replace function fn_area_recibo(p_telefone text, p_cpf text, p_ano integer)
returns jsonb
language plpgsql as $$
declare
    v_g uuid := fn_area_autenticar(p_telefone, p_cpf);
    v_itens jsonb;
begin
    if v_g is null then
        return jsonb_build_object('erro', 'Sessão inválida. Entre de novo com WhatsApp e CPF.');
    end if;
    select coalesce(jsonb_agg(i order by i ->> 'data'), '[]'::jsonb) into v_itens from (
        select jsonb_build_object('data', c.pago_em::date, 'descricao', 'Doação mensal ' || to_char(c.competencia, 'MM/YYYY'),
                                  'valor', c.valor) as i
          from cobranca c join assinatura a on a.id = c.assinatura_id
         where a.guardiao_id = v_g and c.status in ('pago', 'recuperado') and extract(year from c.pago_em) = p_ano
        union all
        select jsonb_build_object('data', d.paga_em::date, 'descricao', 'Doação única', 'valor', d.valor)
          from doacao_unica d
         where d.cpf_hash = (select cpf_hash from guardiao where id = v_g)
           and d.status = 'paga' and extract(year from d.paga_em) = p_ano) x;
    return jsonb_build_object(
        'nome',  (select nome from guardiao where id = v_g),
        'ano',   p_ano,
        'itens', v_itens,
        'total', (select coalesce(sum((e ->> 'valor')::numeric), 0) from jsonb_array_elements(v_itens) e));
end;
$$;

-- Todas as funções com search_path fixo
alter function fn_gerar_cobrancas(date)                                   set search_path = public;
alter function fn_cancelar(uuid, text, date)                              set search_path = public;
alter function fn_processar_evento(text, uuid, text, timestamptz)         set search_path = public;
alter function fn_enviar_impacto_mensal(date, timestamptz)                set search_path = public;
alter function fn_aderir_publico(text, text, text, text, text, numeric, smallint, boolean, text) set search_path = public;
alter function fn_convite_nome(text)                                     set search_path = public;
alter function fn_salvar_impacto(smallint, date, text)                    set search_path = public;
alter function fn_registrar_contato(uuid, text)                           set search_path = public;
alter function fn_simular_gateway(date, numeric, numeric, timestamptz)    set search_path = public;
alter function fn_cadastrar_pix_direto(text, text, text, text, numeric, smallint, boolean, date) set search_path = public;
alter function fn_registrar_pix_direto(uuid, boolean, timestamptz)       set search_path = public;
alter function fn_migrar_para_asaas(uuid)                                 set search_path = public;
alter function fn_convite_valido(text)                                   set search_path = public;
alter function fn_doar_unica(text, text, text, text, text, numeric, boolean, text) set search_path = public;
alter function fn_confirmar_doacao_demo(text)                             set search_path = public;
alter function fn_processar_doacao_unica(text, text, timestamptz)         set search_path = public;
alter function fn_pausar(uuid, integer, date)                             set search_path = public;
alter function fn_retomar(uuid, date)                                     set search_path = public;
alter function fn_area(text, text)                                        set search_path = public;
alter function fn_area_acao(text, text, text, integer, text)              set search_path = public;
alter function fn_area_recibo(text, text, integer)                        set search_path = public;
