# Execução final na véspera (quinta, 08/10/2026)

Checklist da tarefa TE7. Tempo estimado: 30 minutos. Quem executa: responsável pela trilha de Tecnologia.

## 1. Banco ativo e íntegro (5 min)

- [ ] Abrir o painel do Supabase, projeto `clube-guardioes`. Se aparecer *Paused*, clicar em *Restore project* e aguardar.
- [ ] No GitHub, aba **Actions**, conferir que a rotina `manter-supabase-ativo` rodou com sucesso nos últimos 3 dias.

## 2. Testes no Supabase (5 min)

No SQL Editor:

```sql
select * from qa.fn_rodar_testes();       -- esperado: 38 PASS (T01 a T38), nenhuma FALHA
select * from qa.fn_testes_seguranca();   -- esperado: 13 PASS (S01 a S13), nenhuma FALHA
```

- [ ] Exportar o resultado (botão de download do SQL Editor) e salvar como `evidencias/testes_supabase_2026-10-08.log`. Comparar com a última evidência, `evidencias/testes_supabase_2026-09-29_decisoes_29_09.log` (migrações até a 25).

## 3. Zerar a base de demonstração (5 min)

Seguir a seção "Zerar a demonstração" do README. Conferir:

```sql
select count(*) as guardioes,
       count(*) filter (where exists (select 1 from assinatura a
            where a.guardiao_id = g.id and a.status = 'ativa')) as ativos,
       count(*) filter (where exists (select 1 from assinatura a
            where a.guardiao_id = g.id and a.status = 'pausada')) as pausados,
       (select count(*) from doacao_unica) as doacoes_unicas
from guardiao g;   -- esperado: 305, 271, 4 e 48
```

- [ ] Resultado: 305 Guardiões, 271 ativos, 4 pausados, 48 doações únicas.

## 4. Interface publicada (5 min)

- [ ] Abrir a página de adesão: https://steniosouza97-svg.github.io/clube-guardioes-mvp/
- [ ] Conferir a escolha entre "Guardião R$ 85/mês (recomendado)" e "Doação única, qualquer valor".
- [ ] Digitar o CPF `111.111.111-11` e conferir a mensagem "CPF inválido". Não enviar.
- [ ] Clicar em **Minha Área** e em **Entrar como Guardião de demonstração**: conferir Carlos Soares com nível Prata (4 estrelas), impacto, histórico e botão de recibo. Sair sem pausar nem cancelar.
- [ ] Entrar no painel com o login do voluntário e conferir o resumo (275 Guardiões no Clube, sendo 271 ativos e 4 pausados) e a aba **Doações únicas** (48).
- [ ] Deixar as duas abas abertas para a apresentação.

## 5. Pacote técnico (10 min)

- [ ] Link do vídeo inserido em `ENTREGA.md` e no README.
- [ ] Commit da evidência do passo 2: `git add evidencias && git commit -m "Evidência final da véspera"` e `git push`.
- [ ] Baixar o repositório como ZIP e salvar na pasta do Drive `Tecnologia/semana 10`.

## Se algo falhar

| Sintoma | Ação |
|---|---|
| Algum teste com FALHA | Não corrigir às pressas. Registrar em `docs/casos_de_teste.md`, avaliar com o grupo e seguir a regra de congelamento (CONTRIBUTING.md) |
| Painel não carrega dados | Conferir se o projeto está pausado; conferir se o e-mail do voluntário está na tabela `voluntario` |
| Página fora do ar | GitHub, Actions, rodar de novo `publicar_interface`; alternativa: app.netlify.com/drop com a pasta `web/` |
