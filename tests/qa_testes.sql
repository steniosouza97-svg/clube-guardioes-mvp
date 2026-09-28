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
        select count(*) into ativos from assinatura where status = 'ativa';
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

        -- T13 impacto mensal
        select count(*) into ativos from assinatura where status = 'ativa';
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
             = (select count(*) from assinatura where status = 'ativa'), 'T14 contagem de ativos diverge';
        v_log := v_log || format('PASS T14 métricas do painel conferem com os lançamentos (receita de %s: R$ %s)',
                                 to_char(v_ult, 'MM/YYYY'), v_num);

        -- T15 regressão: aviso de atraso para assinatura já cancelada
        r := fn_processar_evento('evt_qa_007', v_cinad, 'PAYMENT_OVERDUE', (v_prox + 5)::timestamptz);
        assert r = 'ignorado', 'T15 aviso de atraso após cancelamento deveria ser ignorado, retornou ' || r;
        v_log := v_log || 'PASS T15 aviso de atraso para assinatura já cancelada é ignorado sem erro'::text;

        -- T16 adesão pela página pública
        ok := fn_aderir_publico('Visitante Site', 'Visitante.Site@Example.com', c7, '(11) 90000-9990',
                                'QR Code na comunidade', 80, 10::smallint, true);
        assert ok, 'T16 adesão pública não retornou sucesso';
        assert exists (select 1 from vw_situacao_guardiao where email = 'visitante.site@example.com'
                          and situacao = 'ativo' and origem = 'QR Code na comunidade'),
               'T16 adesão pública não registrada com a origem';
        falhou := false;
        begin
            perform fn_aderir_publico('Valor Alto', 'valor.alto@example.com', c8, null, null, 99999, 10::smallint, true);
        exception when others then falhou := true;
        end;
        assert falhou, 'T16 adesão pública aceitou valor fora do limite';
        v_log := v_log || 'PASS T16 adesão pela página pública registra a origem e limita o valor'::text;

        -- T17 simulador do gateway
        perform setseed(0.5);
        perform fn_gerar_cobrancas(v_comp);
        select count(*) into n from cobranca c join assinatura a on a.id = c.assinatura_id
         where c.competencia = v_comp and c.status = 'pendente' and a.status = 'ativa';
        select count(*) into n1 from evento_gateway;
        v_res := fn_simular_gateway(v_comp, 0.91, 0.60, (v_comp + 28)::timestamptz + interval '12 hours');
        select count(*) into n2 from evento_gateway;
        assert not exists (select 1 from cobranca c join assinatura a on a.id = c.assinatura_id
                            where c.competencia = v_comp and c.status = 'pendente' and a.status = 'ativa'),
               'T17 simulador deixou cobrança pendente';
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
        assert not exists (select 1 from guardiao where email not like '%@example.com'),
               'T20 base de demonstração contém e-mail fora do domínio reservado';
        v_log := v_log || 'PASS T20 integridade: uma assinatura ativa por Guardião, um CPF por Guardião, todo pagamento rastreável, nenhum dado pessoal real'::text;
    exception when assert_failure or others then
        v_log := v_log || ('FALHA ' || sqlerrm);
    end;

    return query select i, v_log[i] from generate_subscripts(v_log, 1) i;
end;
$f$;

revoke all on function qa.fn_rodar_testes() from public;
