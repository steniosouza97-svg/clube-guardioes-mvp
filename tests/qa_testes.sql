-- =====================================================================
-- qa_testes.sql: suíte de testes do fluxo principal
--
-- Cria a função qa.fn_rodar_testes(), que executa todos os testes e
-- devolve o resultado como tabela. Funciona igual no Supabase (SQL
-- Editor) e num PostgreSQL local:
--
--     select * from qa.fn_rodar_testes();
--
-- Os testes do fluxo rodam num bloco que é desfeito ao final: nenhum
-- dado é alterado. Usam um mês futuro sem movimento, então podem ser
-- repetidos a qualquer momento, inclusive depois da demonstração.
-- Uma linha FALHA indica o primeiro teste que não passou.
-- =====================================================================

create schema if not exists qa;
revoke all on schema qa from public;

create or replace function qa.fn_rodar_testes()
returns table (ordem integer, resultado text)
language plpgsql
set search_path = public
as $f$
declare
    v_log    text[] := '{}';
    v_ult    date;      -- último mês com cobranças na base
    v_comp   date;      -- mês de teste, sem movimento
    v_prox   date;
    v_a      uuid;
    v_a1     uuid;
    v_g      uuid;
    v_g1     uuid;
    v_c      uuid;
    v_c1     uuid;
    v_cinad  uuid;
    n        integer;
    n1       integer;
    n2       integer;
    ativos   integer;
    r        text;
    ok       boolean;
    falhou   boolean;
    v_res    jsonb;
    v_num    numeric;
    v_num2   numeric;
    -- CPFs fictícios válidos para os testes (série 700.000.0xx)
    c1 text := '700000001' || fn_cpf_digitos('700000001');
    c2 text := '700000002' || fn_cpf_digitos('700000002');
    c3 text := '700000003' || fn_cpf_digitos('700000003');
    c4 text := '700000004' || fn_cpf_digitos('700000004');
    c5 text := '700000005' || fn_cpf_digitos('700000005');
    c6 text := '700000006' || fn_cpf_digitos('700000006');
    c7 text := '700000007' || fn_cpf_digitos('700000007');
    c8 text := '700000008' || fn_cpf_digitos('700000008');
    c9 text := '700000009' || fn_cpf_digitos('700000009');
    c11 text := '700000011' || fn_cpf_digitos('700000011');
    c12 text := '700000012' || fn_cpf_digitos('700000012');
    c13 text := '700000013' || fn_cpf_digitos('700000013');
    c14 text := '700000014' || fn_cpf_digitos('700000014');
    v_cod   text;       -- código de convite (jornada da semana 5)
    c16 text := '700000016' || fn_cpf_digitos('700000016');
    c17 text := '700000017' || fn_cpf_digitos('700000017');
    c18 text := '700000018' || fn_cpf_digitos('700000018');
    c19 text := '700000019' || fn_cpf_digitos('700000019');
    c20 text := '700000020' || fn_cpf_digitos('700000020');
    v_ap    uuid;
    v_data  date;
    v_gc    uuid;
    v_ad    uuid;       -- assinatura em Pix direto (modelo híbrido)
    v_ad2   uuid;
    v_cd    uuid;
    v_seg   date;
begin
    select max(competencia) into v_ult from cobranca;
    v_comp := (date_trunc('month', coalesce(v_ult, current_date)) + interval '3 months')::date;
    v_prox := (v_comp + interval '1 month')::date;
    v_log  := v_log || format('INFO mês de teste: %s (último mês com movimento: %s)', v_comp, v_ult);

    begin   -- bloco dos testes do fluxo: desfeito ao final

        -- T01 adesão
        v_a1 := fn_aderir('Teste Guardião', 'Teste.Um@Example.com', c1, '(11) 90000-9999', 'QR Code na comunidade',
                          80, 10::smallint, 'pix', true, v_comp - 10);
        select guardiao_id into v_g1 from assinatura where id = v_a1 and status = 'ativa';
        assert v_g1 is not null, 'T01 assinatura ativa não criada';
        assert (select email from guardiao where id = v_g1) = 'teste.um@example.com', 'T01 e-mail não normalizado';
        assert (select count(*) from comunicacao where guardiao_id = v_g1 and tipo = 'boas_vindas') = 1,
               'T01 boas-vindas não enviada';
        v_log := v_log || 'PASS T01 adesão válida cria Guardião, assinatura ativa e mensagem de boas-vindas'::text;

        -- T02 sem consentimento
        falhou := false;
        begin
            perform fn_aderir('Sem Consentimento', 'sem.consentimento@example.com', c2, null, 'Instagram',
                              60, 5::smallint, 'pix', false, v_comp - 10);
        exception when others then
            falhou := sqlerrm like '%Consentimento LGPD%';
        end;
        assert falhou, 'T02 adesão sem consentimento foi aceita';
        v_log := v_log || 'PASS T02 adesão sem consentimento LGPD é rejeitada'::text;

        -- T03 e-mail inválido
        falhou := false;
        begin
            perform fn_aderir('Email Ruim', 'email-sem-arroba', c3, null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then
            falhou := sqlerrm like '%E-mail inválido%';
        end;
        assert falhou, 'T03 e-mail inválido foi aceito';
        v_log := v_log || 'PASS T03 e-mail inválido é rejeitado'::text;

        -- T04 duas assinaturas ativas
        falhou := false;
        begin
            perform fn_aderir('Teste Guardião', 'teste.um@example.com', c1, null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then
            falhou := sqlerrm like '%já possui assinatura ativa%';
        end;
        assert falhou, 'T04 segunda assinatura ativa foi aceita';
        v_log := v_log || 'PASS T04 o mesmo CPF não pode ter duas assinaturas ativas'::text;

        -- T05 cobrança mensal
        -- ativos, mais os pausados cuja pausa termina neste mês (voltam sozinhos)
        select count(*) into ativos from assinatura
         where status = 'ativa' or (status = 'pausada' and pausada_ate <= v_comp);
        n1 := fn_gerar_cobrancas(v_comp + 14);
        n2 := fn_gerar_cobrancas(v_comp);
        assert n1 = ativos, format('T05 esperava %s cobranças, gerou %s', ativos, n1);
        assert n2 = 0, 'T05 geração não é idempotente';
        select id into v_c1 from cobranca where assinatura_id = v_a1 and competencia = v_comp;
        assert (select vencimento from cobranca where id = v_c1) = v_comp + 9, 'T05 vencimento incorreto';
        v_log := v_log || format('PASS T05 cobrança mensal gerada para todos os %s Guardiões ativos, sem duplicar', ativos);

        -- T06 pagamento
        r := fn_processar_evento('evt_qa_001', v_c1, 'PAYMENT_RECEIVED', (v_comp + 9)::timestamptz + interval '12 hours');
        assert r = 'pago', 'T06 retorno inesperado: ' || r;
        assert (select status from cobranca where id = v_c1) = 'pago', 'T06 cobrança não ficou paga';
        assert (select count(*) from comunicacao where cobranca_id = v_c1 and tipo = 'agradecimento') = 1, 'T06 sem agradecimento';
        v_log := v_log || 'PASS T06 pagamento aprovado marca a cobrança como paga e envia agradecimento'::text;

        -- T07 idempotência
        r := fn_processar_evento('evt_qa_001', v_c1, 'PAYMENT_RECEIVED', (v_comp + 9)::timestamptz + interval '12 hours 5 minutes');
        assert r = 'duplicado', 'T07 evento repetido não foi detectado';
        assert (select count(*) from comunicacao where cobranca_id = v_c1 and tipo = 'agradecimento') = 1, 'T07 agradecimento duplicado';
        v_log := v_log || 'PASS T07 evento repetido do gateway não produz efeito duas vezes (idempotência)'::text;

        -- T08 falha
        v_a := fn_aderir('Teste Falha', 'teste.falha@example.com', c4, '(11) 90000-9998', 'Instagram',
                         60, 5::smallint, 'pix', true, v_comp - 10);
        perform fn_gerar_cobrancas(v_comp);
        select id into v_c from cobranca where assinatura_id = v_a and competencia = v_comp;
        r := fn_processar_evento('evt_qa_002', v_c, 'PAYMENT_OVERDUE', (v_comp + 5)::timestamptz + interval '8 hours');
        assert r = 'falhou', 'T08 retorno inesperado: ' || r;
        assert (select tentativas from cobranca where id = v_c) = 1, 'T08 tentativa não contada';
        assert (select count(*) from comunicacao where cobranca_id = v_c and tipo = 'recuperacao') = 1, 'T08 sem mensagem de recuperação';
        assert exists (select 1 from vw_alerta_churn where cobranca_id = v_c), 'T08 não apareceu no alerta de churn';
        assert (select situacao from vw_situacao_guardiao where assinatura_id = v_a) = 'em_risco', 'T08 situação não é em_risco';
        v_log := v_log || 'PASS T08 falha de pagamento aciona recuperação e coloca o Guardião no alerta de churn'::text;

        -- T09 recuperação
        r := fn_processar_evento('evt_qa_003', v_c, 'PAYMENT_RECEIVED', (v_comp + 7)::timestamptz + interval '15 hours');
        assert r = 'recuperado', 'T09 retorno inesperado: ' || r;
        assert not exists (select 1 from vw_alerta_churn where cobranca_id = v_c), 'T09 continuou no alerta';
        v_log := v_log || 'PASS T09 pagamento após falha marca a cobrança como recuperada e tira o Guardião do alerta'::text;

        -- T10 inadimplência
        v_a := fn_aderir('Teste Inadimplente', 'teste.inadimplente@example.com', c5, null, 'WhatsApp',
                         30, 15::smallint, 'pix', true, v_comp - 10);
        perform fn_gerar_cobrancas(v_comp);
        select id into v_cinad from cobranca where assinatura_id = v_a and competencia = v_comp;
        perform fn_processar_evento('evt_qa_004', v_cinad, 'PAYMENT_OVERDUE', (v_comp + 15)::timestamptz);
        perform fn_processar_evento('evt_qa_005', v_cinad, 'PAYMENT_OVERDUE', (v_comp + 21)::timestamptz);
        r := fn_processar_evento('evt_qa_006', v_cinad, 'PAYMENT_OVERDUE', (v_comp + 27)::timestamptz);
        assert r = 'cancelado_por_inadimplencia', 'T10 retorno inesperado: ' || r;
        assert (select status || '/' || motivo_cancelamento from assinatura where id = v_a) = 'cancelada/inadimplencia',
               'T10 assinatura não foi cancelada por inadimplência';
        assert (select situacao from vw_situacao_guardiao where assinatura_id = v_a) = 'cancelado', 'T10 situação incorreta';
        v_log := v_log || 'PASS T10 três falhas seguidas cancelam a assinatura por inadimplência'::text;

        -- T11 cancelamento voluntário
        v_a := fn_aderir('Teste Cancela', 'teste.cancela@example.com', c6, null, 'Site institucional',
                         120, 20::smallint, 'pix', true, v_comp - 10);
        perform fn_gerar_cobrancas(v_comp);
        perform fn_cancelar(v_a, 'voluntario', v_comp + 11);
        assert (select status from cobranca where assinatura_id = v_a and competencia = v_comp) = 'cancelado',
               'T11 cobrança pendente não foi cancelada';
        perform fn_gerar_cobrancas(v_prox);
        assert not exists (select 1 from cobranca where assinatura_id = v_a and competencia = v_prox),
               'T11 gerou cobrança para assinatura cancelada';
        assert (select count(*) from comunicacao c join assinatura a on a.guardiao_id = c.guardiao_id
                 where a.id = v_a and c.tipo = 'cancelamento') = 1, 'T11 sem mensagem de cancelamento';
        v_log := v_log || 'PASS T11 cancelamento voluntário encerra a assinatura e interrompe as cobranças'::text;

        -- T12 retorno de ex-Guardião
        select guardiao_id into v_g from assinatura where id = v_a;
        v_a := fn_aderir('Teste Cancela', 'teste.cancela@example.com', c6, null, 'Site institucional',
                         60, 20::smallint, 'pix', true, v_prox + 19);
        assert (select guardiao_id from assinatura where id = v_a) = v_g, 'T12 reativação criou um novo Guardião';
        assert (select count(*) from assinatura where guardiao_id = v_g) = 2, 'T12 histórico da assinatura anterior perdido';
        v_log := v_log || 'PASS T12 ex-Guardião pode voltar com o mesmo e-mail, preservando o histórico'::text;

        -- T13 impacto mensal: só sai com a prestação de contas do mês registrada
        select count(*) into ativos from assinatura where status = 'ativa';
        falhou := false;
        begin
            perform fn_enviar_impacto_mensal(v_comp, (v_comp + 27)::timestamptz + interval '18 hours');
        exception when others then falhou := sqlerrm like '%Registre em Atividades%';
        end;
        assert falhou, 'T13 notícia de impacto enviada sem prestação de contas registrada';
        perform fn_salvar_impacto(a.id, v_comp, 'Sustentou as atividades de teste do mês.') from atividade a where a.ativa;
        n1 := fn_enviar_impacto_mensal(v_comp, (v_comp + 27)::timestamptz + interval '18 hours');
        n2 := fn_enviar_impacto_mensal(v_comp, (v_comp + 27)::timestamptz + interval '18 hours 30 minutes');
        assert n1 = ativos, format('T13 esperava %s mensagens, enviou %s', ativos, n1);
        assert n2 = 0, 'T13 mensagem de impacto duplicada no mesmo mês';
        v_log := v_log || format('PASS T13 mensagem mensal de impacto chega uma vez a cada um dos %s Guardiões ativos', ativos);

        -- T14 métricas do painel
        select receita into v_num from vw_metricas_mensais where mes = v_ult;
        select coalesce(sum(valor), 0) into v_num2 from cobranca where competencia = v_ult and status in ('pago', 'recuperado');
        assert v_num = v_num2, format('T14 receita da view %s difere da soma %s', v_num, v_num2);
        assert (select count(*) from vw_situacao_guardiao where situacao <> 'cancelado')
             = (select count(*) from assinatura where status in ('ativa', 'pausada')), 'T14 contagem de ativos diverge';
        v_log := v_log || format('PASS T14 métricas do painel conferem com os lançamentos (receita de %s: R$ %s)',
                                 to_char(v_ult, 'MM/YYYY'), v_num);

        -- T15 regressão: aviso de atraso para assinatura já cancelada
        r := fn_processar_evento('evt_qa_007', v_cinad, 'PAYMENT_OVERDUE', (v_prox + 5)::timestamptz);
        assert r = 'ignorado', 'T15 aviso de atraso após cancelamento deveria ser ignorado, retornou ' || r;
        v_log := v_log || 'PASS T15 aviso de atraso para assinatura já cancelada é ignorado sem erro'::text;

        -- T16 adesão pela página pública
        v_res := fn_aderir_publico('Visitante Site', 'Visitante.Site@Example.com', c7, '(11) 90000-9990',
                                   'QR Code na comunidade', 85, 10::smallint, true);
        assert v_res ->> 'primeiro_nome' = 'Visitante' and length(v_res ->> 'codigo_convite') = 8,
               'T16 adesão pública não devolveu os dados da confirmação';
        assert exists (select 1 from vw_situacao_guardiao where email = 'visitante.site@example.com'
                          and situacao = 'ativo' and origem = 'QR Code na comunidade'),
               'T16 adesão pública não registrada com a origem';
        falhou := false;
        begin
            perform fn_aderir_publico('Valor Menor', 'valor.menor@example.com', c8, null, null, 60, 10::smallint, true);
        exception when others then falhou := true;
        end;
        assert falhou, 'T16 adesão pública aceitou Guardião com valor diferente de R$ 85';
        v_log := v_log || 'PASS T16 adesão pela página pública registra a origem e o Guardião doa R$ 85 por mês'::text;

        -- T17 simulador do gateway
        perform setseed(0.5);
        perform fn_gerar_cobrancas(v_comp);
        select count(*) into n from cobranca c join assinatura a on a.id = c.assinatura_id
         where c.competencia = v_comp and c.status = 'pendente' and a.status = 'ativa' and a.meio_pagamento <> 'pix_direto';
        select count(*) into n1 from evento_gateway;
        v_res := fn_simular_gateway(v_comp, 0.91, 0.60, (v_comp + 28)::timestamptz + interval '12 hours');
        select count(*) into n2 from evento_gateway;
        assert not exists (select 1 from cobranca c join assinatura a on a.id = c.assinatura_id
                            where c.competencia = v_comp and c.status = 'pendente' and a.status = 'ativa'
                              and a.meio_pagamento <> 'pix_direto'),
               'T17 simulador deixou cobrança da Asaas pendente';
        assert n2 - n1 >= n, 'T17 simulador não registrou um evento por cobrança';
        assert coalesce((v_res ->> 'pago')::int, 0) > 0.8 * n, 'T17 taxa de pagamento simulada fora do esperado';
        v_log := v_log || format('PASS T17 simulador do gateway processou %s cobranças pelo mesmo caminho do webhook: %s', n, v_res);

        -- T18 proteção do gerador
        falhou := false;
        begin
            perform fn_gerar_dados_sinteticos();
        exception when others then falhou := true;
        end;
        assert falhou, 'T18 gerador rodou sobre base já populada';
        v_log := v_log || 'PASS T18 gerador de dados sintéticos se recusa a rodar sobre base existente'::text;

        -- T21 CPF inválido
        falhou := false;
        begin
            perform fn_aderir('CPF Errado', 'cpf.errado@example.com', left(c9, 10) || ((right(c9, 1)::int + 1) % 10)::text,
                              null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then falhou := sqlerrm like '%CPF inválido%';
        end;
        assert falhou, 'T21 CPF com dígito verificador errado foi aceito';
        falhou := false;
        begin
            perform fn_aderir('CPF Repetido', 'cpf.repetido@example.com', '111.111.111-11', null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then falhou := sqlerrm like '%CPF inválido%';
        end;
        assert falhou, 'T21 CPF com dígitos todos iguais foi aceito';
        assert fn_cpf_valido('529.982.247-25') and not fn_cpf_valido('529.982.247-24') and not fn_cpf_valido('123'),
               'T21 validação de CPF incorreta';
        v_log := v_log || 'PASS T21 CPF inválido é recusado (dígito verificador, números repetidos, tamanho)'::text;

        -- T22 duplicidade por CPF
        falhou := false;
        begin
            perform fn_aderir('Outro Email Mesmo CPF', 'outro.email@example.com', c1, null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then falhou := sqlerrm like '%CPF já possui assinatura ativa%';
        end;
        assert falhou, 'T22 mesmo CPF com outro e-mail foi aceito';
        falhou := false;
        begin
            perform fn_aderir('Mesmo Email Outro CPF', 'teste.um@example.com', c9, null, 'Instagram', 60, 5::smallint, 'pix', true, v_comp - 10);
        exception when others then falhou := sqlerrm like '%E-mail já cadastrado para outro CPF%';
        end;
        assert falhou, 'T22 mesmo e-mail com outro CPF foi aceito';
        assert (select count(*) from guardiao where email = 'teste.um@example.com') = 1, 'T22 Guardião duplicado';
        v_log := v_log || 'PASS T22 duplicidade barrada pelo CPF, mesmo com outro e-mail, e e-mail não troca de dono'::text;

        -- T23 CPF nunca gravado em texto aberto
        assert not exists (select 1 from guardiao g where g::text like '%' || c1 || '%' or g::text like '%' || left(c1, 3) || '.' || substr(c1, 4, 3) || '%'),
               'T23 CPF encontrado em texto aberto na tabela guardiao';
        assert (select cpf_hash from guardiao where id = v_g1) ~ '^[0-9a-f]{64}$', 'T23 cpf_hash fora do formato';
        assert (select cpf_hash from guardiao where id = v_g1) <> encode(extensions.digest(c1, 'sha256'), 'hex'),
               'T23 cpf_hash sem chave secreta (reversível por força bruta)';
        v_log := v_log || 'PASS T23 CPF gravado só como impressão digital com chave secreta, nunca em texto aberto'::text;

        -- T24 consulta por CPF
        assert (select nome from fn_consultar_cpf(c1)) = 'Teste Guardião', 'T24 consulta não encontrou o Guardião';
        assert not exists (select 1 from fn_consultar_cpf(c9)), 'T24 consulta encontrou CPF não cadastrado';
        v_log := v_log || 'PASS T24 consulta por CPF encontra o Guardião sem revelar o número'::text;

        -- T25 modelo híbrido: Guardião da base entra no painel sem trocar a forma de pagar
        v_ad := fn_cadastrar_pix_direto('Base Direta', 'base.direta@example.com', c11, '(11) 90000-1111',
                                        80, 10::smallint, true, v_comp - 10);
        assert (select meio_pagamento from assinatura where id = v_ad) = 'pix_direto', 'T25 assinatura não ficou em Pix direto';
        assert (select o.nome from assinatura a join guardiao g on g.id = a.guardiao_id join origem o on o.id = g.origem_id
                 where a.id = v_ad) = 'Base Pix manual', 'T25 origem da base não registrada';
        falhou := false;
        begin
            perform fn_cadastrar_pix_direto('Base Sem Consentimento', 'base.sem@example.com', c12, null, 80, 10::smallint, false, v_comp - 10);
        exception when others then falhou := sqlerrm like '%Consentimento LGPD%';
        end;
        assert falhou, 'T25 base cadastrada sem consentimento LGPD';
        v_log := v_log || 'PASS T25 Guardião da base entra no painel em Pix direto, com CPF e consentimento, sem trocar a forma de pagar'::text;

        -- T26 Pix direto: a Asaas não vê; o voluntário registra à mão pelo mesmo caminho do webhook
        perform fn_gerar_cobrancas(v_prox);
        select id into v_cd from cobranca where assinatura_id = v_ad and competencia = v_prox;
        assert v_cd is not null, 'T26 cobrança do Pix direto não gerada';
        perform fn_simular_gateway(v_prox, 1, 1, (v_prox + 20)::timestamptz);
        assert (select status from cobranca where id = v_cd) = 'pendente', 'T26 simulador da Asaas processou Pix direto';
        r := fn_registrar_pix_direto(v_cd, true, (v_prox + 11)::timestamptz);
        assert r = 'pago', 'T26 registro manual não pagou: ' || r;
        assert exists (select 1 from comunicacao where cobranca_id = v_cd and tipo = 'agradecimento'), 'T26 agradecimento não registrado';
        assert exists (select 1 from evento_gateway where cobranca_id = v_cd and id_evento like 'manual_%'), 'T26 registro manual sem rastro';
        falhou := false;
        begin
            perform fn_registrar_pix_direto((select c.id from cobranca c join assinatura a on a.id = c.assinatura_id
                                              where c.competencia = v_prox and a.meio_pagamento = 'pix' limit 1), true);
        exception when others then falhou := sqlerrm like '%Cobrança da Asaas%';
        end;
        assert falhou, 'T26 registro manual aceito em cobrança da Asaas';
        v_log := v_log || 'PASS T26 Pix direto fica fora do simulador da Asaas, é registrado à mão com agradecimento e rastro, e cobrança da Asaas não aceita registro manual'::text;

        -- T27 Pix direto não recebido: lembrete e alerta de churn, igual à Asaas
        v_ad2 := fn_cadastrar_pix_direto('Base Esquecida', 'base.esquecida@example.com', c12, '(11) 90000-2222',
                                         60, 15::smallint, true, v_comp - 10);
        perform fn_gerar_cobrancas(v_prox);
        r := fn_registrar_pix_direto((select id from cobranca where assinatura_id = v_ad2 and competencia = v_prox), false,
                                     (v_prox + 20)::timestamptz);
        assert r = 'falhou', 'T27 não recebido não virou atraso: ' || r;
        assert exists (select 1 from vw_alerta_churn where nome = 'Base Esquecida'), 'T27 Guardião fora do alerta de churn';
        v_log := v_log || 'PASS T27 Pix direto não recebido gera lembrete e coloca o Guardião no alerta de churn'::text;

        -- T28 migração para a Asaas
        perform fn_migrar_para_asaas(v_ad);
        assert (select meio_pagamento from assinatura where id = v_ad) = 'pix', 'T28 migração não mudou o meio';
        assert (select valor_mensal from assinatura where id = v_ad) = 80, 'T28 migração alterou o valor';
        falhou := false;
        begin perform fn_migrar_para_asaas(v_ad); exception when others then falhou := true; end;
        assert falhou, 'T28 migração repetida foi aceita';
        v_seg := (v_prox + interval '1 month')::date;
        perform fn_gerar_cobrancas(v_seg);
        perform fn_simular_gateway(v_seg, 1, 1, (v_seg + 20)::timestamptz);
        assert (select status from cobranca where assinatura_id = v_ad and competencia = v_seg) = 'pago',
               'T28 cobrança do Guardião migrado não passou pela Asaas';
        v_log := v_log || 'PASS T28 migração para a Asaas mantém valor e histórico, não se repete e a cobrança seguinte passa pela Asaas'::text;

        -- T29 convite: o link pessoal registra quem convidou e o canal de indicação
        select g.codigo_convite, g.id into v_cod, v_gc
          from guardiao g join assinatura a on a.guardiao_id = g.id and a.status = 'ativa'
         order by g.entrou_em limit 1;
        assert fn_convite_nome(upper(v_cod)) = split_part((select nome from guardiao where id = v_gc), ' ', 1),
               'T29 nome de quem convidou não encontrado pelo código';
        v_res := fn_aderir_publico('Convidada Teste', 'convidada.teste@example.com', c13, '(11) 90000-1313',
                                   'Site institucional', 85, 15::smallint, true, v_cod);
        select id into v_g from guardiao where email = 'convidada.teste@example.com';
        assert (select indicado_por from guardiao where id = v_g) = v_gc, 'T29 indicação não registrada';
        assert (select o.nome from guardiao g join origem o on o.id = g.origem_id where g.id = v_g) = 'Indicação de Guardião',
               'T29 canal de indicação não registrado';
        assert v_res ->> 'convidado_por' is not null, 'T29 confirmação não devolveu quem convidou';
        v_res := fn_aderir_publico('Sem Convite', 'sem.convite@example.com', c14, null,
                                   'Instagram', 85, 15::smallint, true, 'naoexiste');
        assert (select indicado_por from guardiao where email = 'sem.convite@example.com') is null
           and (select o.nome from guardiao g join origem o on o.id = g.origem_id where g.email = 'sem.convite@example.com') = 'Instagram',
               'T29 código de convite inválido alterou a indicação';
        v_log := v_log || 'PASS T29 link pessoal de convite registra quem convidou e o canal de indicação; código inválido é ignorado'::text;

        -- T30 prestação de contas por atividade: a notícia do mês leva o texto registrado pela equipe
        perform fn_salvar_impacto(a.id, v_prox, 'Primeira versão do texto do mês.') from atividade a where a.ativa;
        perform fn_salvar_impacto(a.id, v_prox, 'Garantiu refeições e apoio escolar no mês de teste.') from atividade a where a.nome = 'Contraturno Escolar';
        assert (select count(*) from impacto_mensal where competencia = v_prox) = (select count(*) from atividade where ativa),
               'T30 texto do mês duplicado ao atualizar';
        falhou := false;
        begin
            perform fn_salvar_impacto(a.id, v_prox, 'curto') from atividade a limit 1;
        exception when others then falhou := true;
        end;
        assert falhou, 'T30 texto de impacto vazio ou curto foi aceito';
        n := fn_enviar_impacto_mensal(v_prox, (v_prox + 27)::timestamptz + interval '18 hours');
        assert n > 0 and not exists (select 1 from comunicacao where tipo = 'impacto_mensal' and competencia = v_prox
                                         and conteudo not like '%Garantiu refeições e apoio escolar no mês de teste.%'),
               'T30 notícia do mês não levou o texto da atividade';
        v_log := v_log || format('PASS T30 prestação de contas por atividade registrada pela equipe chega aos %s Guardiões na notícia do mês', n);

        -- T31 contato pessoal registrado aparece no alerta de churn
        select guardiao_id into v_g from vw_alerta_churn limit 1;
        assert v_g is not null, 'T31 alerta de churn vazio no mês de teste';
        perform fn_registrar_contato(v_g, 'Liguei, vai pagar sexta.');
        assert (select ultimo_contato from vw_alerta_churn where guardiao_id = v_g limit 1) is not null,
               'T31 contato registrado não aparece no alerta';
        assert (select conteudo from comunicacao where guardiao_id = v_g and tipo = 'contato_pessoal'
                 order by enviada_em desc limit 1) = 'Liguei, vai pagar sexta.', 'T31 anotação do contato perdida';
        v_log := v_log || 'PASS T31 contato pessoal feito pela equipe fica registrado e aparece no alerta de churn'::text;

        -- T32 e-mail opcional (decisão de 29/09)
        v_res := fn_aderir_publico('Sem Email Um', null, c16, '(11) 96666-0016', 'Instagram', 85, 10::smallint, true);
        v_res := fn_aderir_publico('Sem Email Dois', '', c17, '(11) 96666-0017', 'Instagram', 85, 10::smallint, true);
        assert (select count(*) from guardiao where cpf_hash in (fn_cpf_hash(c16), fn_cpf_hash(c17)) and email is null) = 2,
               'T32 Guardião sem e-mail não foi aceito';
        falhou := false;
        begin
            perform fn_aderir_publico('Email Ruim', 'sem-arroba', c18, null, 'Instagram', 85, 10::smallint, true);
        exception when others then falhou := true;
        end;
        assert falhou, 'T32 e-mail informado e inválido foi aceito';
        v_log := v_log || 'PASS T32 e-mail é opcional; se informado, precisa ser válido'::text;

        -- T33 doação única de qualquer valor, confirmação e convite a partir dela
        v_res := fn_doar_unica('Doadora Unica', null, c18, '(11) 96666-0018', 'Instagram', 37, true);
        v_cod := v_res ->> 'codigo_convite';
        assert (select status from doacao_unica where codigo_convite = v_cod) = 'pendente', 'T33 doação única não ficou pendente';
        assert fn_convite_nome(v_cod) is null, 'T33 convite de doação ainda não paga foi aceito';
        assert fn_confirmar_doacao_demo(v_cod) = 'paga', 'T33 confirmação da demonstração falhou';
        assert fn_confirmar_doacao_demo(v_cod) = 'nada_a_confirmar', 'T33 confirmação repetida teve efeito';
        assert fn_convite_nome(v_cod) = 'Doadora', 'T33 link de convite de quem fez doação única não funcionou';
        v_res := fn_aderir_publico('Convidado Da Doadora', null, c19, '(11) 96666-0019', 'Instagram', 85, 10::smallint, true, v_cod);
        assert (select convite_usado from guardiao where cpf_hash = fn_cpf_hash(c19)) = v_cod
           and (select o.nome from guardiao g join origem o on o.id = g.origem_id where g.cpf_hash = fn_cpf_hash(c19)) = 'Indicação de Guardião',
               'T33 indicação de quem fez doação única não registrada';
        falhou := false;
        begin perform fn_doar_unica('Valor Baixo', null, c20, null, null, 5, true); exception when others then falhou := true; end;
        assert falhou, 'T33 doação única abaixo de R$ 10 aceita';
        falhou := false;
        begin perform fn_doar_unica('Sem Consentimento', null, c20, null, null, 50, false); exception when others then falhou := true; end;
        assert falhou, 'T33 doação única sem consentimento aceita';
        v_log := v_log || 'PASS T33 doação única aceita qualquer valor a partir de R$ 10, é confirmada uma vez e gera link de convite'::text;

        -- T34 pausa: cancela o mês em aberto, não gera cobrança durante a pausa e volta sozinha
        v_ap := fn_aderir('Guardiao Pausa', null, c20, '(11) 96666-0020', 'Instagram', 85, 10::smallint, 'pix', true, v_comp - 10);
        perform fn_gerar_cobrancas(v_comp);
        v_data := fn_pausar(v_ap, 2, v_comp + 3);
        assert v_data = (v_comp + interval '2 months')::date and (select status from assinatura where id = v_ap) = 'pausada',
               'T34 pausa com data de volta incorreta: ' || v_data;
        assert (select status from cobranca where assinatura_id = v_ap and competencia = v_comp) = 'cancelado',
               'T34 cobrança do mês pausado continuou em aberto';
        perform fn_gerar_cobrancas((v_comp + interval '1 month')::date);
        assert not exists (select 1 from cobranca where assinatura_id = v_ap and competencia = (v_comp + interval '1 month')::date),
               'T34 cobrança gerada durante a pausa';
        assert (select situacao from vw_situacao_guardiao where assinatura_id = v_ap) = 'pausado', 'T34 painel não mostra pausado';
        perform fn_gerar_cobrancas(v_data);
        assert (select status from assinatura where id = v_ap) = 'ativa'
           and exists (select 1 from cobranca where assinatura_id = v_ap and competencia = v_data),
               'T34 doação não voltou sozinha no mês indicado';
        assert exists (select 1 from comunicacao c join assinatura a on a.guardiao_id = c.guardiao_id where a.id = v_ap and c.tipo = 'pausa')
           and exists (select 1 from comunicacao c join assinatura a on a.guardiao_id = c.guardiao_id where a.id = v_ap and c.tipo = 'retomada'),
               'T34 mensagens de pausa e retomada não registradas';
        falhou := false;
        begin perform fn_pausar(v_ap, 4, v_data); exception when others then falhou := true; end;
        assert falhou, 'T34 pausa acima de 3 meses aceita';
        v_log := v_log || 'PASS T34 pausa de 1 a 3 meses cancela o mês em aberto, não cobra durante a pausa e volta sozinha'::text;

        -- T35 Minha Área: entra só com WhatsApp e CPF corretos, sem expor dados pessoais, e bloqueia tentativas
        v_res := fn_area('11966660016', c16);
        assert v_res ->> 'primeiro_nome' = 'Sem' and v_res ->> 'nivel' = 'Guardião'
           and not (v_res ? 'email') and not (v_res ? 'telefone') and not (v_res ? 'cpf'),
               'T35 Minha Área não devolveu os dados certos';
        assert fn_area('(11) 96666-0099', c16) ? 'erro', 'T35 Minha Área aberta com WhatsApp errado';
        for n in 1 .. 5 loop perform fn_area('(11) 95555-0001', c16); end loop;
        falhou := false;
        begin perform fn_area('(11) 95555-0001', c16); exception when others then falhou := sqlerrm like '%Muitas tentativas%'; end;
        assert falhou, 'T35 tentativas repetidas não foram bloqueadas';
        v_log := v_log || 'PASS T35 Minha Área abre só com WhatsApp e CPF do Guardião, sem expor dados, e bloqueia após 5 erros'::text;

        -- T36 ações da própria Guardiã na Minha Área
        v_res := fn_area_acao('11966660017', c17, 'pausar', 1);
        assert v_res ->> 'status' = 'pausada', 'T36 pausa pela Minha Área falhou';
        v_res := fn_area_acao('11966660017', c17, 'retomar');
        assert v_res ->> 'status' = 'ativa', 'T36 retomada pela Minha Área falhou';
        v_res := fn_area_acao('11966660017', c17, 'cancelar', null, 'O valor ficou apertado no momento');
        assert v_res ->> 'status' = 'cancelada'
           and (select motivo_texto from assinatura a join guardiao g on g.id = a.guardiao_id
                 where g.cpf_hash = fn_cpf_hash(c17) and a.status = 'cancelada') = 'O valor ficou apertado no momento',
               'T36 cancelamento com motivo falhou';
        v_res := fn_area_acao('11966660017', c17, 'reativar');
        assert v_res ->> 'status' = 'ativa' and (v_res ->> 'valor')::numeric = 85, 'T36 reativação como Guardião de R$ 85 falhou';
        v_log := v_log || 'PASS T36 pela Minha Área a Guardiã pausa, retoma, cancela com motivo e reativa'::text;

        -- T37 gamificação: 1ª estrela na primeira doação, depois uma a cada 3 meses pagos; Bronze, Prata e Ouro
        assert fn_nivel(0) = 'Guardião' and fn_nivel(3) = 'Guardião Bronze' and fn_nivel(4) = 'Guardião Prata'
           and fn_nivel(5) = 'Guardião Ouro' and fn_nivel(9) = 'Guardião Ouro', 'T37 regra de níveis incorreta';
        assert not exists (select 1 from vw_situacao_guardiao where estrelas <> case when meses_pagos = 0 then 0 else least(5, 1 + meses_pagos / 3) end), 'T37 estrelas fora da regra';
        assert exists (select 1 from vw_situacao_guardiao where meses_pagos = 1 and estrelas = 1)
           and exists (select 1 from vw_situacao_guardiao where meses_pagos = 12 and nivel = 'Guardião Ouro')
           and not exists (select 1 from vw_situacao_guardiao where estrelas > 5), 'T37 1ª doação, 12 meses ou teto de 5 estrelas fora da regra';
        select count(*) into n from vw_situacao_guardiao where nivel in ('Guardião Bronze', 'Guardião Prata', 'Guardião Ouro');
        v_log := v_log || format('PASS T37 1ª estrela na primeira doação e uma a cada 3 meses (Ouro em 12); %s Guardiões já são Bronze ou acima', n);

        -- T38 recibo anual: soma as doações pagas do CPF no ano
        v_res := fn_area_recibo('11966660016', c16, extract(year from current_date)::int);
        assert (v_res ->> 'total')::numeric = coalesce((select sum(c.valor) from cobranca c join assinatura a on a.id = c.assinatura_id
                 join guardiao g on g.id = a.guardiao_id where g.cpf_hash = fn_cpf_hash(c16) and c.status in ('pago', 'recuperado')
                   and extract(year from c.pago_em) = extract(year from current_date)), 0),
               'T38 total do recibo não confere';
        assert fn_area_recibo('11966660016', c17, 2026) ? 'erro', 'T38 recibo emitido com CPF de outra pessoa';
        v_log := v_log || 'PASS T38 recibo anual soma as doações pagas e só sai para o próprio Guardião'::text;

        -- T39 ambiente de demonstração só aceita e-mail @example.com (evento de 29/09)
        falhou := false;
        begin perform fn_aderir_publico('Email Real', 'pessoa.real@gmail.com', c20, null, 'Instagram', 85, 10::smallint, true);
        exception when others then falhou := sqlerrm like 'Ambiente de demonstração%'; end;
        assert falhou, 'T39 adesão com e-mail real aceita na demonstração';
        falhou := false;
        begin perform fn_doar_unica('Email Real', 'pessoa.real@escola.edu.br', c20, null, null, 50, true);
        exception when others then falhou := sqlerrm like 'Ambiente de demonstração%'; end;
        assert falhou, 'T39 doação única com e-mail real aceita na demonstração';
        assert not exists (select 1 from guardiao where email = 'pessoa.real@gmail.com')
           and not exists (select 1 from doacao_unica where email = 'pessoa.real@escola.edu.br'), 'T39 dado real gravado';
        update parametro set valor = 0 where chave = 'modo_demonstracao';
        assert (fn_doar_unica('Producao', 'pessoa.real@escola.edu.br', c20, null, null, 50, true) ->> 'codigo_convite') is not null,
               'T39 fora da demonstração o e-mail comum deveria ser aceito';
        update parametro set valor = 1 where chave = 'modo_demonstracao';
        v_log := v_log || 'PASS T39 demonstração recusa e-mail real (só @example.com ou em branco); em produção o e-mail comum é aceito'::text;

        raise exception 'QA_DESFAZER';
    exception when assert_failure or others then
        if sqlerrm <> 'QA_DESFAZER' then
            v_log := v_log || ('FALHA ' || sqlerrm);
            return query select i, v_log[i] from generate_subscripts(v_log, 1) i;
            return;
        end if;
    end;
    v_log := v_log || 'INFO testes do fluxo desfeitos: nenhum dado foi alterado'::text;

    -- testes de leitura sobre a base carregada
    begin
        select avg(ticket_medio), avg(churn) into v_num, v_num2 from vw_metricas_mensais where churn is not null;
        select ativos_fim into n from vw_metricas_mensais order by mes desc limit 1;
        assert v_num between 70 and 90, 'T19 ticket médio fora da calibração: ' || v_num;
        assert v_num2 between 0.01 and 0.04, 'T19 churn médio fora da calibração: ' || v_num2;
        assert n between 227 and 307, format('T19 base do último mês (%s) fora de ±15%% do plano (267)', n);
        v_log := v_log || format('PASS T19 dados sintéticos calibrados: ticket R$ %s, churn %s%% ao mês, %s Guardiões no último mês (plano: 267)',
                                 round(v_num, 2), round(v_num2 * 100, 2), n);

        assert not exists (select guardiao_id from assinatura where status = 'ativa' group by 1 having count(*) > 1),
               'T20 Guardião com duas assinaturas ativas';
        assert not exists (select 1 from cobranca c where c.status in ('pago', 'recuperado')
                              and not exists (select 1 from evento_gateway e
                                               where e.cobranca_id = c.id and e.tipo = 'PAYMENT_RECEIVED')),
               'T20 cobrança paga sem evento de pagamento do gateway';
        assert (select count(distinct cpf_hash) from guardiao) = (select count(*) from guardiao), 'T20 CPF repetido na base';
        assert not exists (select 1 from guardiao where email not like '%@example.com')
           and not exists (select 1 from doacao_unica where email not like '%@example.com'),
               'T20 base de demonstração contém e-mail fora do domínio reservado';
        v_log := v_log || 'PASS T20 integridade: uma assinatura ativa por Guardião, um CPF por Guardião, todo pagamento rastreável, nenhum dado pessoal real'::text;
    exception when assert_failure or others then
        v_log := v_log || ('FALHA ' || sqlerrm);
    end;

    return query select i, v_log[i] from generate_subscripts(v_log, 1) i;
end;
$f$;

revoke all on function qa.fn_rodar_testes() from public;
