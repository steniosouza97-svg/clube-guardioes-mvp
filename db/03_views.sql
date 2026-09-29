-- =====================================================================
-- 03_views.sql: o que o painel do voluntário mostra
-- As métricas espelham as do business case: base ativa, receita
-- recorrente, ticket médio, churn e cobertura do custeio.
-- =====================================================================

-- Situação atual de cada Guardião
create or replace view vw_situacao_guardiao as
select g.id                    as guardiao_id,
       g.nome,
       g.email,
       g.telefone,
       o.nome                  as origem,
       g.entrou_em,
       a.id                    as assinatura_id,
       a.valor_mensal,
       a.status                as status_assinatura,
       a.iniciada_em,
       a.cancelada_em,
       a.motivo_cancelamento,
       case
           when a.id is null or a.status = 'cancelada' then 'cancelado'
           when a.status = 'pausada' then 'pausado'
           when exists (select 1 from cobranca c
                         where c.assinatura_id = a.id and c.status = 'falhou') then 'em_risco'
           else 'ativo'
       end                     as situacao,
       a.meio_pagamento,
       (select count(*) from guardiao x where x.convite_usado = g.codigo_convite)
     + (select count(*) from doacao_unica d where d.convite_usado = g.codigo_convite) as indicacoes,
       a.pausada_ate,
       n.meses_pagos,
       n.estrelas,
       fn_nivel(n.estrelas)    as nivel
  from guardiao g
  join origem o on o.id = g.origem_id
  left join lateral (
        select * from assinatura a
         where a.guardiao_id = g.id
         order by (a.status in ('ativa', 'pausada')) desc, a.iniciada_em desc
         limit 1) a on true
  cross join lateral (
        select count(*)::int as meses_pagos,
               floor(count(*) / coalesce((select valor from parametro where chave = 'meses_por_estrela'), 3))::int as estrelas
          from cobranca c join assinatura x on x.id = c.assinatura_id
         where x.guardiao_id = g.id and c.status in ('pago', 'recuperado')) n;

-- Alerta de churn: Guardiões ativos com cobrança falhada ainda não recuperada
create or replace view vw_alerta_churn as
select g.nome,
       g.telefone,
       g.email,
       a.valor_mensal,
       c.competencia,
       c.vencimento,
       c.tentativas,
       (current_date - c.vencimento)            as dias_em_atraso,
       case when c.tentativas >= 2 then 'alta' else 'media' end as prioridade,
       c.id                                      as cobranca_id,
       a.id                                      as assinatura_id,
       g.id                                      as guardiao_id,
       (select max(m.enviada_em) from comunicacao m
         where m.guardiao_id = g.id and m.tipo = 'contato_pessoal') as ultimo_contato
  from cobranca c
  join assinatura a on a.id = c.assinatura_id and a.status = 'ativa'
  join guardiao g   on g.id = a.guardiao_id
 where c.status = 'falhou'
 order by c.tentativas desc, c.vencimento;

-- Métricas por mês de competência
create or replace view vw_metricas_mensais as
with meses as (
    select generate_series(min(competencia), max(competencia), interval '1 month')::date as mes
      from cobranca
), base as (
    select m.mes,
           (select count(*) from assinatura a
             where a.iniciada_em < m.mes
               and (a.cancelada_em is null or a.cancelada_em >= m.mes))                          as ativos_inicio,
           (select count(*) from assinatura a
             where date_trunc('month', a.iniciada_em) = m.mes)                                    as novos,
           (select count(*) from assinatura a
             where date_trunc('month', a.cancelada_em) = m.mes)                                   as cancelados,
           (select count(*) from assinatura a
             where a.iniciada_em < (m.mes + interval '1 month')
               and (a.cancelada_em is null or a.cancelada_em >= (m.mes + interval '1 month')))    as ativos_fim,
           (select coalesce(sum(c.valor), 0) from cobranca c
             where c.competencia = m.mes and c.status in ('pago', 'recuperado'))                  as receita,
           (select count(*) from cobranca c
             where c.competencia = m.mes and c.status in ('pago', 'recuperado'))                  as pagantes,
           (select count(*) from cobranca c
             where c.competencia = m.mes and c.status = 'recuperado')                             as recuperadas,
           (select count(*) from cobranca c
             where c.competencia = m.mes and c.status = 'falhou')                                 as em_aberto
      from meses m
)
select mes,
       ativos_inicio,
       novos,
       cancelados,
       ativos_fim,
       receita,
       pagantes,
       recuperadas,
       em_aberto,
       round(receita / nullif(pagantes, 0), 2)                    as ticket_medio,
       round(cancelados::numeric / nullif(ativos_inicio, 0), 4)   as churn
  from base
 order by mes;

-- Resumo do painel: último mês fechado e cobertura do custeio
create or replace view vw_painel_resumo as
with ultimo as (
    select * from vw_metricas_mensais
     where mes < date_trunc('month', current_date)
     order by mes desc limit 1
)
select u.mes                                                        as ultimo_mes_fechado,
       (select count(*) from vw_situacao_guardiao where situacao <> 'cancelado') as guardioes_ativos,
       (select count(*) from vw_alerta_churn)                       as guardioes_em_risco,
       u.receita                                                    as receita_recorrente_mes,
       u.ticket_medio,
       u.churn                                                      as churn_mes,
       round(u.receita * 12 / (select valor from parametro where chave = 'custeio_anual_2025'), 4)
                                                                    as cobertura_custeio_2025,
       (select count(*) from assinatura where status = 'ativa' and meio_pagamento = 'pix_direto')
                                                                    as guardioes_pix_direto,
       (select count(*) from assinatura where status = 'pausada')   as guardioes_pausados,
       (select count(*) from doacao_unica where status = 'paga'
           and paga_em >= date_trunc('month', current_date))        as doacoes_unicas_mes,
       (select coalesce(sum(valor), 0) from doacao_unica where status = 'paga'
           and paga_em >= date_trunc('month', current_date))        as doacoes_unicas_valor_mes
  from ultimo u;

-- Cobranças do mês para a tela do simulador e para o acompanhamento diário
create or replace view vw_cobrancas_mes as
select c.id            as cobranca_id,
       c.competencia,
       g.nome,
       g.telefone,
       c.valor,
       c.vencimento,
       c.status,
       c.tentativas,
       c.pago_em,
       a.status        as status_assinatura,
       a.meio_pagamento
  from cobranca c
  join assinatura a on a.id = c.assinatura_id
  join guardiao g   on g.id = a.guardiao_id;

-- Resultado por canal de aquisição: mede as 56 h mensais de aquisição
create or replace view vw_origem_resultado as
select o.nome                                                  as origem,
       o.tipo,
       count(g.id)                                             as guardioes,
       count(a.id) filter (where a.status = 'ativa')           as ativos,
       coalesce(sum(a.valor_mensal) filter (where a.status = 'ativa'), 0) as receita_mensal_ativa
  from origem o
  left join guardiao g   on g.origem_id = o.id
  left join assinatura a on a.guardiao_id = g.id
 group by o.nome, o.tipo
 order by guardioes desc;

-- Doações únicas (não recorrentes), para o painel
create or replace view vw_doacoes_unicas as
select d.codigo_convite  as codigo,
       d.nome,
       d.telefone,
       d.email,
       d.valor,
       d.status,
       o.nome            as origem,
       d.criada_em,
       d.paga_em,
       fn_convite_nome(d.convite_usado) as convidado_por,
       (select count(*) from guardiao g where g.convite_usado = d.codigo_convite)
     + (select count(*) from doacao_unica x where x.convite_usado = d.codigo_convite) as indicacoes
  from doacao_unica d
  join origem o on o.id = d.origem_id
 order by d.criada_em desc;
