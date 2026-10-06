# Como manter o MVP

Regras para quem for alterar o código ou o banco do Clube Guardiões do Futuro.

## Toda alteração

1. **Roda as três camadas de teste antes do commit:**
   - no Supabase: `select * from qa.fn_rodar_testes();` e `select * from qa.fn_testes_seguranca();` (39 e 13 aprovados);
   - localmente: `./tests/rodar_testes.sh`;
   - interface: `./tests/e2e/rodar_e2e.sh` (25 passos aprovados).
2. **Guarda a evidência em `evidencias/`**, com a data no nome do arquivo.
3. **Muda o banco só por migração versionada** (arquivos de `db/`), nunca pelo Table Editor. A próxima migração é a 33.
4. **Diz no commit o que mudou e o teste que protege a mudança**, por exemplo: `Corrige X; protegido por T35`.

## Sempre

- Nenhum dado real de doador no repositório nem na base de demonstração: e-mails `@example.com` (quando informados), CPFs e telefones fictícios.
- A chave secreta do Supabase e a chave de API da Asaas nunca entram em `web/` nem no repositório.
- Só imagens de crianças liberadas pelo Instituto, conforme sua política e o Manual de Boas Práticas para Redes Sociais.
- Nenhuma promessa de dedução de Imposto de Renda.
