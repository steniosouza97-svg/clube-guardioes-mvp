# Regra de congelamento do MVP

Válida de **sábado, 03/10/2026**, até a apresentação de **09/10/2026**.

O vídeo demonstrativo e as evidências de teste retratam uma versão exata do MVP. Mudar o código depois disso pode deixar o vídeo desatualizado ou quebrar o que foi testado. Por isso:

1. **Só entram correções de defeito.** Nada de funcionalidade nova, mudança visual ou refatoração.
2. **Toda correção roda as três camadas de teste antes do commit:**
   - no Supabase: `select * from qa.fn_rodar_testes();` e `select * from qa.fn_testes_seguranca();` (38 e 13 aprovados);
   - localmente: `./tests/rodar_testes.sh`;
   - interface: `./tests/e2e/rodar_e2e.sh` (25 passos aprovados, conforme `evidencias/e2e/resultado_e2e.log`).
3. **A evidência nova vai para `evidencias/`**, com a data no nome do arquivo.
4. **A correção é avaliada contra o vídeo.** Se a tela mudar, o grupo decide entre regravar a cena ou registrar a diferença em `docs/casos_de_teste.md`.
5. **Mudança no banco do Supabase só por migração versionada** (arquivos de `db/`), nunca pelo Table Editor. A última aplicada até 29/09 é a 25; a próxima correção entra como 26.
6. **O commit diz o defeito e o teste que o protege**, por exemplo: `Corrige X; protegido por T35`.

## Sempre, congelado ou não

- Nenhum dado real de doador no repositório nem na base de demonstração: e-mails `@example.com` (quando informados, pois o e-mail é opcional), CPFs e telefones fictícios. O Guardião de demonstração da Minha Área é sintético.
- A chave secreta do Supabase e a chave de API da Asaas nunca entram em `web/` nem no repositório.
- Só imagens de crianças liberadas pelo Instituto, conforme sua política e o Manual de Boas Práticas para Redes Sociais (a foto atual faz parte do banco liberado).
- Nenhuma promessa de dedução de Imposto de Renda.
