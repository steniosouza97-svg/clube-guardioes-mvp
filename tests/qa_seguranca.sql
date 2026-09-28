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

        assert fn_aderir_publico('Seguranca Anonimo', 'seguranca.anonimo@example.com', v_cpf, null,
                                 'Site institucional', 50, 5::smallint, true), 'S03 adesão pública falhou';
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

        -- pessoa com login, mas fora da lista de voluntários
        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims', '{"role":"authenticated","email":"curioso@example.com"}', true);
        select count(*) into n from vw_situacao_guardiao;
        assert n = 0, 'S05 conta sem cadastro de voluntário leu Guardiões';
        bloq := false;
        begin perform fn_simular_gateway(current_date); exception when insufficient_privilege then bloq := true; end;
        assert bloq, 'S05 conta sem cadastro de voluntário executou o fluxo';
        v_log := v_log || 'PASS S05 conta criada por terceiro, sem cadastro de voluntário, não vê dados nem executa o fluxo'::text;

        -- voluntário cadastrado
        perform set_config('role', 'postgres', true);
        insert into voluntario (email, nome) values ('voluntario.teste@example.com', 'Voluntário de Teste');
        perform set_config('role', 'authenticated', true);
        perform set_config('request.jwt.claims', '{"role":"authenticated","email":"voluntario.teste@example.com"}', true);

        select count(*) into n from vw_situacao_guardiao;
        assert n > 0, 'S06 voluntário deveria ler o painel';
        assert fn_simular_gateway((current_date + interval '5 years')::date) is not null, 'S06 voluntário não executou o fluxo';
        v_log := v_log || format('PASS S06 voluntário cadastrado lê o painel (%s Guardiões) e executa o fluxo', n);

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
