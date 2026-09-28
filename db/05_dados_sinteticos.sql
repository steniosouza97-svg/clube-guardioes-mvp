-- =====================================================================
-- 05_dados_sinteticos.sql: DADOS SINTÉTICOS para demonstração e testes
--
-- Cria a função fn_gerar_dados_sinteticos e a executa. O gerador roda
-- dentro do banco, sem arquivo externo: basta colar este arquivo no
-- SQL Editor do Supabase.
--
-- Calibrado com o business case (plano com uma pessoa, 80 h/mês):
--   - 35 Guardiões iniciais, base Pix manual (dado real do Instituto)
--   - conversão de 30 doadores pontuais no primeiro mês
--   - 20 novos Guardiões por mês
--   - ticket próximo de R$ 80 e churn próximo de 2% ao mês
--
-- Nenhum dado pessoal real: nomes aleatórios, e-mails no domínio
-- reservado example.com, telefones fictícios, CPFs fictícios da série
-- 800.000.xxx (gravados só cifrados), ids externos "sint".
-- Mesma semente e mesma data geram os mesmos dados.
--
-- NUNCA executar em produção. A função se recusa a rodar se encontrar
-- qualquer Guardião com e-mail fora do domínio example.com.
-- =====================================================================

create or replace function fn_gerar_dados_sinteticos(
    p_hoje         date             default '2026-09-28',
    p_meses        integer          default 12,
    p_semente      double precision default 0.2026,
    p_base_inicial integer          default 35,
    p_conversao    integer          default 30,
    p_novos_mes    integer          default 20
) returns text
language plpgsql as $$
declare
    nomes      text[] := array['Ana','Beatriz','Camila','Daniela','Elaine','Fernanda','Gabriela','Helena',
                               'Isabela','Juliana','Larissa','Mariana','Natália','Patrícia','Renata','Sabrina',
                               'Tatiane','Vanessa','Aline','Bruna','Carla','Débora','Eduarda','Flávia','Giovana',
                               'Adriano','Bruno','Carlos','Diego','Eduardo','Felipe','Gustavo','Henrique','Igor',
                               'João','Leandro','Marcelo','Nelson','Otávio','Paulo','Rafael','Sérgio','Thiago',
                               'Vinícius','Wagner','André','Caio','Fábio','Lucas','Mateus'];
    sobrenomes text[] := array['Almeida','Barbosa','Cardoso','Castro','Correia','Costa','Dias','Farias',
                               'Fernandes','Freitas','Gomes','Lima','Lopes','Machado','Martins','Medeiros',
                               'Mendes','Monteiro','Moraes','Moreira','Nascimento','Nunes','Oliveira','Pereira',
                               'Pinto','Ramos','Reis','Ribeiro','Rocha','Santos','Silva','Soares','Souza',
                               'Teixeira','Vieira'];
    dias_venc  int[]  := array[5, 10, 15, 20, 25, 28];
    inicio     date   := (date_trunc('month', p_hoje) - make_interval(months => p_meses - 1))::date;
    comp       date;
    fim        date;
    ult        date;
    venc       date;
    base_pag   date;
    t          date;
    d          date;
    v_entrou   date;
    quando     timestamptz;
    r          double precision;
    recupera   boolean;
    tent       integer;
    dias       integer;
    n_g        integer := 0;
    n_c        integer := 0;
    n_e        integer := 0;
    i          integer;
    m          integer;
    s          record;
    v_cob      uuid;
    v_origem   text;
    v_nome     text;
    v_sobren   text;
    v_g        uuid;
    v_valor    numeric;
begin
    if exists (select 1 from guardiao where email not like '%@example.com') then
        raise exception 'Base contém Guardiões reais. O gerador de dados sintéticos não roda em produção.';
    end if;
    if exists (select 1 from guardiao) then
        raise exception 'Base já possui dados. Limpe as tabelas antes de gerar de novo.';
    end if;

    perform setseed(p_semente);

    for m in 0 .. p_meses - 1 loop
        comp := (inicio + make_interval(months => m))::date;
        ult  := (comp + interval '1 month' - interval '1 day')::date;
        fim  := least(ult, p_hoje);

        -- entradas do mês: base atual e conversão no primeiro mês, novos todo mês
        for i in 1 .. (case when m = 0 then p_base_inicial + p_conversao else 0 end) + p_novos_mes loop
            if m = 0 and i <= p_base_inicial then
                v_origem := 'Base Pix manual';
                d := comp;
                v_entrou := least(date '2024-03-01' + floor(random() * 541)::int, comp);
            else
                if m = 0 and i <= p_base_inicial + p_conversao then
                    v_origem := 'Conversão de doador pontual';
                else
                    r := random() * (1 + case when extract(month from comp) in (10, 12) then 0.25 else 0 end);
                    v_origem := case
                        when r < 0.30 then 'QR Code na comunidade'
                        when r < 0.50 then 'Instagram'
                        when r < 0.65 then 'WhatsApp'
                        when r < 0.85 then 'Indicação de Guardião'
                        when r < 0.90 then 'Site institucional'
                        when extract(month from comp) = 10 then 'Campanha Dia das Crianças'
                        when extract(month from comp) = 12 then 'Campanha de Natal'
                        else 'Site institucional' end;
                end if;
                d := comp + floor(random() * ((fim - comp) + 1))::int;
                v_entrou := d;
            end if;

            n_g := n_g + 1;
            v_nome   := nomes[1 + floor(random() * array_length(nomes, 1))::int];
            v_sobren := sobrenomes[1 + floor(random() * array_length(sobrenomes, 1))::int];
            r := random();
            v_valor := case when r < 0.18 then 30 when r < 0.56 then 60 when r < 0.80 then 80
                            when r < 0.96 then 120 else 300 end;

            insert into guardiao (nome, email, cpf_hash, telefone, origem_id, consentimento_lgpd, consentimento_em,
                                  entrou_em, id_externo_gateway)
            values (v_nome || ' ' || v_sobren,
                    translate(lower(v_nome || '.' || v_sobren), 'áéíóúãõçâêô', 'aeiouaocaeo')
                        || '.' || lpad(n_g::text, 4, '0') || '@example.com',
                    -- CPF fictício com dígitos verificadores válidos (série 800.000.xxx), gravado só cifrado
                    fn_cpf_hash(lpad((800000000 + n_g)::text, 9, '0') || fn_cpf_digitos(lpad((800000000 + n_g)::text, 9, '0'))),
                    '(11) 90000-' || lpad(n_g::text, 4, '0'),
                    (select id from origem where nome = v_origem),
                    true,
                    v_entrou::timestamptz + interval '9 hours',
                    v_entrou,
                    'cus_sint_' || lpad(n_g::text, 5, '0'))
            returning id into v_g;

            insert into assinatura (guardiao_id, valor_mensal, dia_vencimento, meio_pagamento, iniciada_em,
                                    id_externo_gateway)
            values (v_g, v_valor, dias_venc[1 + floor(random() * 6)::int], 'pix', d,
                    'sub_sint_' || lpad(n_g::text, 5, '0'));

            insert into comunicacao (guardiao_id, tipo, enviada_em)
            values (v_g, 'boas_vindas', d::timestamptz + interval '10 hours');
        end loop;

        -- cobrança do mês para as assinaturas vigentes
        for s in select a.* from assinatura a
                  where a.iniciada_em <= ult
                    and (a.cancelada_em is null or a.cancelada_em >= comp)
                  order by a.id_externo_gateway loop
            n_c  := n_c + 1;
            venc := make_date(extract(year from comp)::int, extract(month from comp)::int, s.dia_vencimento);
            insert into cobranca (assinatura_id, competencia, valor, vencimento, status, id_externo_gateway)
            values (s.id, comp, s.valor_mensal, venc,
                    case when s.cancelada_em is not null then 'cancelado' else 'pendente' end,
                    'pay_sint_' || lpad(n_c::text, 6, '0'))
            returning id into v_cob;

            continue when s.cancelada_em is not null or venc > p_hoje;

            base_pag := greatest(venc, s.iniciada_em);
            r := random();
            if r < 0.91 then
                quando := (base_pag + floor(random() * 3)::int)::timestamptz + interval '12 hours';
                continue when quando::date > p_hoje;
                update cobranca set status = 'pago', pago_em = quando where id = v_cob;
                n_e := n_e + 1;
                insert into evento_gateway values ('evt_sint_' || lpad(n_e::text, 6, '0'), 'PAYMENT_RECEIVED', v_cob, quando);
                insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo, enviada_em)
                values (s.guardiao_id, v_cob, comp, 'agradecimento', quando);
            else
                recupera := r < 0.986;   -- 1,4% das cobranças terminam em cancelamento por inadimplência
                tent := 0;
                foreach dias in array array[1, 7, 14] loop
                    t := base_pag + dias;
                    exit when t > p_hoje;
                    tent := tent + 1;
                    quando := t::timestamptz + interval '8 hours';
                    n_e := n_e + 1;
                    insert into evento_gateway values ('evt_sint_' || lpad(n_e::text, 6, '0'), 'PAYMENT_OVERDUE', v_cob, quando);
                    insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo, enviada_em)
                    values (s.guardiao_id, v_cob, comp, 'recuperacao', quando);
                    update cobranca set status = 'falhou', tentativas = tent where id = v_cob;
                    if recupera and tent >= 1 + floor(random() * 2)::int then
                        quando := (t + floor(random() * 4)::int)::timestamptz + interval '15 hours';
                        if quando::date <= p_hoje then
                            update cobranca set status = 'recuperado', pago_em = quando where id = v_cob;
                            n_e := n_e + 1;
                            insert into evento_gateway values ('evt_sint_' || lpad(n_e::text, 6, '0'), 'PAYMENT_RECEIVED', v_cob, quando);
                            insert into comunicacao (guardiao_id, cobranca_id, competencia, tipo, enviada_em)
                            values (s.guardiao_id, v_cob, comp, 'agradecimento', quando);
                        end if;
                        exit;
                    end if;
                    if tent >= 3 then
                        update assinatura set status = 'cancelada', cancelada_em = t, motivo_cancelamento = 'inadimplencia'
                         where id = s.id;
                        insert into comunicacao (guardiao_id, tipo, enviada_em)
                        values (s.guardiao_id, 'cancelamento', t::timestamptz + interval '9 hours');
                        exit;
                    end if;
                end loop;
            end if;
        end loop;

        -- cancelamento voluntário, apenas em meses encerrados
        if ult < p_hoje then
            for s in select a.* from assinatura a
                      where a.status = 'ativa' and a.iniciada_em < comp
                      order by a.id_externo_gateway loop
                if random() < 0.006 then
                    t := ult - floor(random() * 6)::int;
                    update assinatura set status = 'cancelada', cancelada_em = t, motivo_cancelamento = 'voluntario'
                     where id = s.id;
                    insert into comunicacao (guardiao_id, tipo, enviada_em)
                    values (s.guardiao_id, 'cancelamento', t::timestamptz + interval '9 hours');
                end if;
            end loop;
        end if;

        -- mensagem mensal de impacto no dia 28 para quem está ativo
        d := make_date(extract(year from comp)::int, extract(month from comp)::int, 28);
        if d <= p_hoje then
            insert into comunicacao (guardiao_id, competencia, tipo, enviada_em)
            select a.guardiao_id, comp, 'impacto_mensal', d::timestamptz + interval '18 hours'
              from assinatura a
             where a.iniciada_em <= d and (a.cancelada_em is null or a.cancelada_em > d);
        end if;
    end loop;

    -- cobranças pendentes de assinaturas canceladas
    update cobranca c set status = 'cancelado'
      from assinatura a
     where a.id = c.assinatura_id and a.status = 'cancelada' and c.status = 'pendente';

    return format('%s Guardiões (%s ativos), %s cobranças, %s eventos | %s a %s',
                  n_g, (select count(*) from assinatura where status = 'ativa'), n_c, n_e, inicio, p_hoje);
end;
$$;

comment on function fn_gerar_dados_sinteticos is
    'Gera dados sintéticos calibrados com o business case. Somente para demonstração e testes.';

alter function fn_gerar_dados_sinteticos(date, integer, double precision, integer, integer, integer) set search_path = public;

select fn_gerar_dados_sinteticos();
