-- =====================================================================
-- qa_seguranca.sql: testes das regras de acesso (arquivo 06)
--
--     select * from qa.fn_testes_seguranca();
--
-- Executa consultas como visitante anônimo (anon) e como voluntário
-- autenticado (authenticated). Tudo é desfeito ao final.
-- Requer os papéis anon e authenticated (existem no Supabase).
-- =====================================================================

create schema if not exists qa;

create or replace function qa.fn_testes_seguranca()
returns table (ordem integer, resultado text)
language plpgsql
set search_path = public
as $f$
declare
    v_log  text[] := '{}';
    n      integer;
    bloq   boolean;
    v_cpf  text := '700000010' || fn_cpf_digitos('700000010');   -- calculado antes de trocar de papel
    v_cpf2 text := '700000015' || fn_cpf_digitos('700000015');
    v_area jsonb;
    v_cod  text := (select g.codigo_convite from guardiao g
                     where exists (select 1 from assinatura a where a.guardiao_id = g.id and a.status = 'ativa')
                     order by g.entrou_em limit 1);
begin
    begin
        -- visitante anônimo
        perform set_config('role', 'anon', true);

        select count(*) into n from origem;
        assert n > 0, 'S01 anônimo deveria ler as origens ativas';
        bloq := false;
        begin perform count(*) from guardiao; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S01 anônimo leu dados de Guardiões';
        v_log := v_log || 'PASS S01 anônimo lê as origens e não lê dados de Guardiões'::text;

        bloq := false;
        begin perform fn_gerar_cobrancas(current_date); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S02 anônimo executou função do painel';
        v_log := v_log || 'PASS S02 anônimo não executa funções do painel'::text;

        assert (fn_aderir_publico('Seguranca Anonimo', 'seguranca.anonimo@example.com', v_cpf, null,
                                  'Site institucional', 85, 5::smallint, true) ->> 'codigo_convite') is not null,
               'S03 adesão pública falhou';
        v_log := v_log || 'PASS S03 anônimo consegue aderir pela página pública'::text;

        bloq := false;
        begin
            insert into guardiao (nome, email, origem_id, consentimento_lgpd) values ('Invasor', 'x@example.com', 1, true);
        exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S04 anônimo gravou direto na tabela';
        v_log := v_log || 'PASS S04 anônimo não grava direto nas tabelas'::text;

        bloq := false;
        begin perform fn_consultar_cpf('52998224725'); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S09 anônimo consultou CPF';
        v_log := v_log || 'PASS S09 anônimo não consulta CPF'::text;

        bloq := false;
        begin perform fn_cadastrar_pix_direto('X', 'x@example.com', v_cpf, null, 80, 10::smallint, true); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S11 anônimo cadastrou Guardião em Pix direto';
        bloq := false;
        begin perform fn_registrar_pix_direto(gen_random_uuid(), true); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S11 anônimo registrou Pix direto';
        bloq := false;
        begin perform fn_migrar_para_asaas(gen_random_uuid()); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S11 anônimo migrou assinatura';

        -- jornada da semana 5: o anônimo só descobre o primeiro nome de quem convidou
        assert fn_convite_nome(v_cod) is not null, 'S12 anônimo não resolveu o link de convite';
        bloq := false;
        begin perform count(*) from impacto_mensal; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S12 anônimo leu a prestação de contas interna';
        bloq := false;
        begin perform fn_salvar_impacto(1::smallint, current_date, 'Texto de teste do mês.'); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S12 anônimo registrou impacto';
        bloq := false;
        begin perform fn_registrar_contato(gen_random_uuid(), null); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S12 anônimo registrou contato';

        -- decisões de 29/09: doação única e Minha Área pelo anônimo, sem expor dados
        assert (fn_doar_unica('Doador Anonimo', null, v_cpf2, '(11) 97777-0015', 'Instagram', 40, true) ->> 'codigo_convite') is not null,
               'S13 anônimo não conseguiu fazer doação única';
        bloq := false;
        begin perform count(*) from doacao_unica; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S13 anônimo leu doações únicas';
        bloq := false;
        begin perform count(*) from tentativa_acesso; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S13 anônimo leu tentativas de acesso';
        v_area := fn_area('(11) 97777-0015', v_cpf2);
        assert v_area ? 'erro', 'S13 Minha Área aberta para quem não é Guardião';
        v_area := fn_area('(11) 90000-9910', v_cpf);    -- Guardião criado no S03 sem telefone: não entra
        assert v_area ? 'erro', 'S13 Minha Área aberta sem conferir o WhatsApp';
        bloq := false;
        begin perform fn_pausar(gen_random_uuid(), 1); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S13 anônimo pausou assinatura pelo painel';
        bloq := false;
        begin perform fn_processar_doacao_unica('x', 'PAYMENT_RECEIVED'); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S13 anônimo confirmou doação única pelo caminho do webhook';
        v_log := v_log || 'PASS S13 anônimo faz doação única e entra na Minha Área só com WhatsApp e CPF corretos; não lê doações nem pausa pelo painel'::text;

        -- pessoa com login, mas fora da lista de voluntários
        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims', '{"role":"authenticated","email":"curioso@example.com"}', true);
        select count(*) into n from vw_situacao_guardiao;
        assert n = 0, 'S05 conta sem cadastro de voluntário leu Guardiões';
        bloq := false;
        begin perform fn_simular_gateway(current_date); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S05 conta sem cadastro de voluntário executou o fluxo';
        bloq := false;
        begin perform fn_registrar_pix_direto(gen_random_uuid(), true); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S11 conta sem cadastro de voluntário registrou Pix direto';
        bloq := false;
        begin perform fn_salvar_impacto(1::smallint, current_date, 'Texto de teste do mês.'); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S12 conta sem cadastro de voluntário registrou impacto';
        v_log := v_log || 'PASS S05 conta criada por terceiro, sem cadastro de voluntário, não vê dados nem executa o fluxo'::text;
        v_log := v_log || 'PASS S11 só voluntário cadastrado registra Pix direto, cadastra a base e migra para a Asaas'::text;

        -- voluntário cadastrado
        perform set_config('role', 'postgres', true);
        insert into voluntario (email, nome) values ('voluntario.teste@example.com', 'Voluntário de Teste');
        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims', '{"role":"authenticated","email":"voluntario.teste@example.com"}', true);

        select count(*) into n from vw_situacao_guardiao;
        assert n > 0, 'S06 voluntário deveria ler o painel';
        assert fn_simular_gateway((current_date + interval '5 years')::date) is not null, 'S06 voluntário não executou o fluxo';
        v_log := v_log || format('PASS S06 voluntário cadastrado lê o painel (%s Guardiões) e executa o fluxo', n);
        select count(*) into n from vw_doacoes_unicas;
        assert n > 0, 'S13 voluntário deveria ler as doações únicas';
        bloq := false;
        begin perform cpf_hash from doacao_unica limit 1; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S13 voluntário leu o CPF cifrado da doação única';
        v_log := v_log || format('PASS S13 voluntário lê as %s doações únicas sem o CPF cifrado', n);
        select count(*) into n from atividade;
        assert n > 0, 'S12 voluntário deveria ler as atividades';
        v_log := v_log || 'PASS S12 convite só revela o primeiro nome; prestação de contas e contatos só pela equipe cadastrada'::text;

        bloq := false;
        begin update assinatura set valor_mensal = 1000; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S07 voluntário alterou tabela sem passar pelas funções';
        v_log := v_log || 'PASS S07 voluntário não altera tabelas sem passar pelas funções'::text;

        bloq := false;
        begin perform cpf_hash from guardiao limit 1; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S10 voluntário leu a coluna de CPF cifrado';
        bloq := false;
        begin perform valor from privado.segredo; exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S10 voluntário leu a chave do CPF';
        bloq := false;
        begin perform fn_cpf_hash('52998224725'); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S10 voluntário calculou impressão digital de CPF';
        v_log := v_log || 'PASS S10 voluntário não lê o CPF cifrado, nem a chave, nem calcula impressões digitais'::text;

        bloq := false;
        begin perform fn_gerar_dados_sinteticos(); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S08 voluntário executou o gerador de dados sintéticos';
        v_log := v_log || 'PASS S08 gerador de dados sintéticos bloqueado fora do SQL Editor'::text;

        raise exception 'QA_DESFAZER';
    exception when assert_failure or others then
        if sqlerrm <> 'QA_DESFAZER' then
            v_log := v_log || ('FALHA ' || sqlerrm);
        end if;
    end;
    v_log := v_log || 'INFO testes de acesso desfeitos: nenhum dado foi alterado'::text;
    return query select i, v_log[i] from generate_subscripts(v_log, 1) i;
end;
$f$;

revoke all on function qa.fn_testes_seguranca() from public;
