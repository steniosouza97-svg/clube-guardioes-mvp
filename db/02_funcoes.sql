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
    v_email      text := lower(trim(p_email));
    v_cpf_hash   text;
begin
    if not coalesce(p_consentimento, false) then
        raise exception 'Consentimento LGPD é obrigatório para aderir ao Clube';
    end if;
    if v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
        raise exception 'E-mail inválido: %', p_email;
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
    select id into v_outro    from guardiao where email = v_email;
    if v_outro is not null and v_outro is distinct from v_guardiao then
        raise exception 'E-mail já cadastrado para outro CPF: %', v_email;
    end if;

    if v_guardiao is null then
        insert into guardiao (nome, email, cpf_hash, telefone, origem_id, consentimento_lgpd, entrou_em)
        values (trim(p_nome), v_email, v_cpf_hash, p_telefone, v_origem, true, p_data)
        returning id into v_guardiao;
    elsif exists (select 1 from assinatura where guardiao_id = v_guardiao and status = 'ativa') then
        raise exception 'Este CPF já possui assinatura ativa no Clube';
    else
        -- ex-Guardião voltando: mantém o histórico e atualiza o contato
        update guardiao
           set email = v_email, telefone = coalesce(p_telefone, telefone),
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
       set status = 'cancelada', cancelada_em = greatest(p_data, iniciada_em), motivo_cancelamento = p_motivo
     where id = p_assinatura and status = 'ativa'
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
     where a.status = 'ativa'
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
    v_origem     text := coalesce(p_origem, 'Site institucional');
begin
    if p_valor is null or p_valor < 10 or p_valor > 5000 then
        raise exception 'Valor mensal deve estar entre R$ 10 e R$ 5.000';
    end if;
    if length(coalesce(p_nome, '')) > 120 or length(coalesce(p_telefone, '')) > 30 then
        raise exception 'Dados de contato inválidos';
    end if;
    -- Convite válido: quem convidou é um Guardião com assinatura ativa
    if nullif(trim(p_convite), '') is not null then
        select g.id into v_padrinho
          from guardiao g
         where g.codigo_convite = lower(trim(p_convite))
           and exists (select 1 from assinatura a where a.guardiao_id = g.id and a.status = 'ativa');
        if v_padrinho is not null then
            v_origem := 'Indicação de Guardião';
        end if;
    end if;

    v_assinatura := fn_aderir(p_nome, p_email, p_cpf, p_telefone, v_origem,
                              p_valor, p_dia, 'pix', p_consentimento, current_date);
    select guardiao_id into v_guardiao from assinatura where id = v_assinatura;

    if v_padrinho is not null and v_padrinho <> v_guardiao then
        update guardiao set indicado_por = v_padrinho
         where id = v_guardiao and indicado_por is null;
    end if;

    -- Devolve só o necessário para as telas seguintes (Pix, confirmação, convite)
    return jsonb_build_object(
        'primeiro_nome',  split_part(trim(p_nome), ' ', 1),
        'valor',          p_valor,
        'dia',            p_dia,
        'codigo_convite', (select codigo_convite from guardiao where id = v_guardiao),
        'convidado_por',  (select split_part(nome, ' ', 1) from guardiao where id = v_padrinho));
end;
$$;

-- Nome de quem convidou, para a faixa "Você foi convidada por..." da página.
-- Devolve só o primeiro nome, e só de Guardião ativo.
create or replace function fn_convite_nome(p_codigo text)
returns text
language sql stable as $$
    select split_part(g.nome, ' ', 1)
      from guardiao g
     where g.codigo_convite = lower(trim(p_codigo))
       and exists (select 1 from assinatura a where a.guardiao_id = g.id and a.status = 'ativa');
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
