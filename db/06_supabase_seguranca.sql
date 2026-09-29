-- =====================================================================
-- 06_supabase_seguranca.sql: aplicar SOMENTE no Supabase
-- (depende dos papéis anon e authenticated, que só existem lá)
--
-- Regras:
--   - Visitante anônimo (página pública do Clube): lê a lista de origens,
--     chama fn_aderir_publico e descobre o primeiro nome de quem o convidou
--     (fn_convite_nome). Nada mais.
--   - Voluntário (login no Supabase E e-mail na tabela voluntario): lê
--     tudo e chama as funções do fluxo. Criar conta não dá acesso.
--   - Nenhum papel grava direto nas tabelas: toda gravação passa pelas
--     funções, que validam as regras de negócio.
--   - O gerador de dados sintéticos só roda pelo SQL Editor.
-- =====================================================================

-- 1. Segurança por linha em todas as tabelas
alter table parametro      enable row level security;
alter table origem         enable row level security;
alter table guardiao       enable row level security;
alter table assinatura     enable row level security;
alter table cobranca       enable row level security;
alter table comunicacao    enable row level security;
alter table evento_gateway enable row level security;
alter table voluntario     enable row level security;   -- sem política: só via SQL Editor
alter table atividade      enable row level security;
alter table impacto_mensal enable row level security;
alter table doacao_unica   enable row level security;
alter table tentativa_acesso enable row level security;   -- sem política: só pelas funções

create policy leitura_voluntario on parametro      for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on origem         for select to authenticated using (eh_voluntario());
create policy leitura_publica    on origem         for select to anon          using (ativa);
create policy leitura_voluntario on guardiao       for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on assinatura     for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on cobranca       for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on comunicacao    for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on evento_gateway for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on atividade      for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on impacto_mensal for select to authenticated using (eh_voluntario());
create policy leitura_voluntario on doacao_unica   for select to authenticated using (eh_voluntario());

-- 2. Privilégios de tabela explícitos (não depender dos padrões do projeto)
revoke all on all tables in schema public from anon, authenticated;
grant usage on schema public to anon, authenticated;
grant select on parametro, origem, assinatura, cobranca, comunicacao, evento_gateway, atividade, impacto_mensal to authenticated;
-- Doação única: o voluntário lê tudo, menos o CPF cifrado
grant select (id, nome, email, telefone, valor, origem_id, convite_usado, codigo_convite, status, consentimento_lgpd,
              criada_em, paga_em, id_externo_gateway) on doacao_unica to authenticated;
-- Guardião: o voluntário lê tudo, menos o CPF cifrado (coluna cpf_hash fica de fora)
grant select (id, nome, email, telefone, origem_id, consentimento_lgpd, consentimento_em,
              entrou_em, id_externo_gateway, criado_em, codigo_convite, indicado_por, convite_usado) on guardiao to authenticated;

-- Esquema privado (chave do CPF): nenhum acesso externo
revoke all on schema privado from anon, authenticated;
revoke all on all tables in schema privado from anon, authenticated;
grant select on origem to anon;

-- 3. Views: respeitam as políticas de quem consulta; só o voluntário lê
alter view vw_situacao_guardiao set (security_invoker = true);
alter view vw_alerta_churn      set (security_invoker = true);
alter view vw_metricas_mensais  set (security_invoker = true);
alter view vw_painel_resumo     set (security_invoker = true);
alter view vw_cobrancas_mes     set (security_invoker = true);
alter view vw_origem_resultado  set (security_invoker = true);
alter view vw_doacoes_unicas    set (security_invoker = true);
grant select on vw_situacao_guardiao, vw_alerta_churn, vw_metricas_mensais, vw_painel_resumo,
                vw_cobrancas_mes, vw_origem_resultado, vw_doacoes_unicas to authenticated;

-- 4. Funções: executam com o dono do banco (security definer) para gravar
--    passando pelas regras, e só são chamáveis por quem deve chamá-las
alter function fn_aderir(text, text, text, text, text, numeric, smallint, text, boolean, date) security definer;
alter function fn_gerar_cobrancas(date)                                   security definer;
alter function fn_cancelar(uuid, text, date)                              security definer;
alter function fn_processar_evento(text, uuid, text, timestamptz)         security definer;
alter function fn_enviar_impacto_mensal(date, timestamptz)                security definer;
alter function fn_aderir_publico(text, text, text, text, text, numeric, smallint, boolean, text) security definer;
alter function fn_convite_nome(text)                                     security definer;
alter function fn_salvar_impacto(smallint, date, text)                    security definer;
alter function fn_registrar_contato(uuid, text)                           security definer;
alter function fn_simular_gateway(date, numeric, numeric, timestamptz)    security definer;
alter function fn_cadastrar_pix_direto(text, text, text, text, numeric, smallint, boolean, date) security definer;
alter function fn_registrar_pix_direto(uuid, boolean, timestamptz)       security definer;
alter function fn_migrar_para_asaas(uuid)                                 security definer;
alter function fn_convite_valido(text)                                   security definer;
alter function fn_doar_unica(text, text, text, text, text, numeric, boolean, text) security definer;
alter function fn_confirmar_doacao_demo(text)                             security definer;
alter function fn_processar_doacao_unica(text, text, timestamptz)         security definer;
alter function fn_pausar(uuid, integer, date)                             security definer;
alter function fn_retomar(uuid, date)                                     security definer;
alter function fn_area(text, text)                                        security definer;
alter function fn_area_acao(text, text, text, integer, text)              security definer;
alter function fn_area_recibo(text, text, integer)                        security definer;

revoke all on all functions in schema public from public, anon, authenticated;

grant execute on function fn_aderir_publico(text, text, text, text, text, numeric, smallint, boolean, text) to anon, authenticated;
grant execute on function fn_convite_nome(text)                                     to anon, authenticated;
-- Doação única e Minha Área do Guardião (visitante anônimo)
grant execute on function fn_doar_unica(text, text, text, text, text, numeric, boolean, text) to anon, authenticated;
grant execute on function fn_confirmar_doacao_demo(text)                             to anon, authenticated;
grant execute on function fn_area(text, text)                                        to anon, authenticated;
grant execute on function fn_area_acao(text, text, text, integer, text)              to anon, authenticated;
grant execute on function fn_area_recibo(text, text, integer)                        to anon, authenticated;
grant execute on function fn_nivel(integer)                                          to authenticated;
grant execute on function fn_processar_doacao_unica(text, text, timestamptz)         to authenticated;
grant execute on function fn_pausar(uuid, integer, date)                             to authenticated;
grant execute on function fn_retomar(uuid, date)                                     to authenticated;
grant execute on function fn_salvar_impacto(smallint, date, text)                    to authenticated;
grant execute on function fn_registrar_contato(uuid, text)                           to authenticated;
grant execute on function fn_consultar_cpf(text)                                    to authenticated;
grant execute on function eh_voluntario() to authenticated;
grant execute on function fn_gerar_cobrancas(date)                                   to authenticated;
grant execute on function fn_cancelar(uuid, text, date)                              to authenticated;
grant execute on function fn_processar_evento(text, uuid, text, timestamptz)         to authenticated;
grant execute on function fn_enviar_impacto_mensal(date, timestamptz)                to authenticated;
grant execute on function fn_simular_gateway(date, numeric, numeric, timestamptz)    to authenticated;
grant execute on function fn_cadastrar_pix_direto(text, text, text, text, numeric, smallint, boolean, date) to authenticated;
grant execute on function fn_registrar_pix_direto(uuid, boolean, timestamptz)       to authenticated;
grant execute on function fn_migrar_para_asaas(uuid)                                 to authenticated;
-- fn_aderir (interna, usada por fn_aderir_publico), fn_cpf_hash, fn_cpf_valido,
-- fn_cpf_digitos e fn_gerar_dados_sinteticos:
-- sem grant. Só pelo SQL Editor.
