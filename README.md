# Clube Guardiões do Começo | MVP funcional

Instituto de Cultura e Lazer Ebenézer | Jardim Ângela, São Paulo
MBA Inteli, Módulo 3 | entrega da semana 10, trilha de Tecnologia

## O que é

Programa de doação recorrente de pessoa física para dar previsibilidade ao custeio do atendimento de 120 crianças. Este repositório contém o MVP que executa o fluxo principal do Clube, com banco de dados, interface, dados sintéticos e testes:

```
página de adesão → cobrança mensal → Pix pago ou vencido → régua de relacionamento → painel com alerta de churn
                                                           (boas-vindas, agradecimento,
                                                            lembrete, notícia de impacto,
                                                            cancelamento)
```

O pagamento real acontece na **Asaas**, gateway que o Instituto já contratou. No MVP, os avisos da Asaas são simulados com os nomes reais dos eventos (`PAYMENT_RECEIVED`, `PAYMENT_OVERDUE`) e passam pela mesma função que o webhook real vai chamar. O banco guarda uma cópia mínima e reconstruível; a Asaas é a fonte da verdade.

## Ambiente de demonstração

| Item | Valor |
|---|---|
| Banco e API | Supabase, projeto `clube-guardioes`, região São Paulo, plano gratuito |
| Endereço da API | `https://fakihzzncafuqtgxnqbi.supabase.co` |
| Repositório | https://github.com/steniosouza97-svg/clube-guardioes-mvp |
| Página de adesão | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html |
| Dados | 305 Guardiões sintéticos, 12 meses de operação simulada (out/2025 a set/2026) |

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `db/` | Esquema, funções do fluxo, views de métricas, dados de referência, gerador de dados sintéticos e regras de acesso |
| `web/` | Interface: página pública de adesão e painel do voluntário. HTML, CSS e JavaScript sem etapa de build |
| `tests/` | Suítes de teste do banco (`qa_*.sql`) e teste ponta a ponta da interface (`e2e/`) |
| `evidencias/` | Resultados das execuções: local, Supabase, controle negativo e capturas de tela |
| `docs/` | Modelo de dados, decisões técnicas, casos de teste e roteiro do vídeo |
| `.github/workflows/` | Rotina que impede a pausa do Supabase gratuito |

Documentação de handover:

- [Modelo de dados](docs/modelo_de_dados.md)
- [Principais decisões técnicas](docs/decisoes_tecnicas.md)
- [Casos de teste e evidências](docs/casos_de_teste.md)
- [Roteiro do vídeo demonstrativo](docs/roteiro_video.md)
- [Privacidade e LGPD: feito e pendências](docs/lgpd_pendencias.md)
- [User stories e critérios de aceite](docs/user_stories.md)
- [Conferência cruzada deck × MVP](docs/coerencia_deck_mvp.md)
- [Execução final na véspera](docs/execucao_final.md)
- [Regra de congelamento](CONTRIBUTING.md)
- [Pacote de entrega da semana 10](ENTREGA.md)

## Instalação no Supabase (uma vez, cerca de 20 minutos)

1. Criar um projeto no plano gratuito, região São Paulo. Para a operação real, a conta deve pertencer ao Instituto (ver "Passagem para o Instituto").
2. Em **SQL Editor**, executar os arquivos nesta ordem, colando o conteúdo de cada um:

   | Arquivo | O que faz | Em produção |
   |---|---|---|
   | `db/01_schema.sql` | Tabelas, restrições e índices | Sim |
   | `db/02_funcoes.sql` | Fluxo principal, adesão pública e simulador | Sim |
   | `db/03_views.sql` | Métricas do painel | Sim |
   | `db/04_dados_referencia.sql` | Parâmetros e canais reais | Sim |
   | `db/05_dados_sinteticos.sql` | Cria e roda o gerador de dados sintéticos | **Não** |
   | `db/06_supabase_seguranca.sql` | Regras de acesso | Sim |
   | `tests/qa_testes.sql` e `tests/qa_seguranca.sql` | Instalam as suítes de teste no esquema `qa` | Sim |

3. Em **Authentication > Users > Add user**, criar o usuário da pessoa dedicada ao Clube (e-mail e senha, marcando o e-mail como confirmado).
4. Autorizar esse e-mail como voluntário, no SQL Editor:
   ```sql
   insert into voluntario (email, nome) values ('email.da.pessoa@dominio.org', 'Nome da pessoa');
   ```
   Criar conta não dá acesso: só e-mails desta tabela veem dados e operam o painel.
5. Em **Authentication > Sign In / Providers**, desligar **Allow new users to sign up**. O banco já barra quem não é voluntário; desligar o cadastro evita contas inúteis.
6. Em **Project Settings > API Keys**, copiar a chave publicável (`sb_publishable_...`) e a URL para `web/config.js`. A chave secreta e a chave de API da Asaas **nunca** vão para a interface.
7. Rodar os testes (próxima seção) e guardar o resultado em `evidencias/`.

## Testes

**No Supabase (SQL Editor):**

```sql
select * from qa.fn_rodar_testes();       -- 28 testes do fluxo
select * from qa.fn_testes_seguranca();   -- 11 testes de acesso
```

Cada linha traz `PASS`, `INFO` ou `FALHA`. Os testes rodam num bloco desfeito ao final: nenhum dado é alterado. Usam um mês futuro sem movimento, então podem ser repetidos a qualquer momento, inclusive depois da demonstração.

**Localmente (PostgreSQL 14+):**

```bash
export PGHOST=localhost PGPORT=5432 PGUSER=postgres
./tests/rodar_testes.sh              # recria o banco, carrega tudo e roda as duas suítes
```

**Interface, ponta a ponta (local):** `tests/e2e/rodar_e2e.sh` sobe o banco com o PostgREST (o mesmo motor de API do Supabase) e percorre 19 passos no navegador com Playwright: adesão com CPF, consulta de CPF, login, resumo, exportação, operação do mês, alerta, recuperação, inadimplência, cancelamento e celular. Gera capturas em `evidencias/e2e/`.

Evidências atuais: 28 de 28 testes do fluxo e 11 de 11 de acesso no Supabase e localmente, 19 de 19 passos de interface, e dois controles negativos que provam que a suíte detecta defeitos (idempotência do webhook e cifragem do CPF).

## Publicar a interface

A pasta `web/` é estática. Neste repositório, a rotina `.github/workflows/publicar_interface.yml` publica a pasta no GitHub Pages a cada alteração (configuração única: Settings > Pages > Source: GitHub Actions).

Alternativa sem GitHub: em app.netlify.com/drop, arrastar a pasta `web/`.

Depois de publicar, gerar os links de cada canal para medir a aquisição:

| Canal | Link |
|---|---|
| QR Code na comunidade | `.../index.html?origem=qr` |
| Instagram | `.../index.html?origem=instagram` |
| WhatsApp | `.../index.html?origem=whatsapp` |
| Indicação de Guardião | `.../index.html?origem=indicacao` |
| Campanha Dia das Crianças | `.../index.html?origem=criancas` |
| Campanha de Natal | `.../index.html?origem=natal` |

## Zerar a demonstração

Antes de cada ensaio ou gravação, no SQL Editor do Supabase:

```sql
truncate evento_gateway, comunicacao, cobranca, assinatura, guardiao restart identity;
select fn_gerar_dados_sinteticos();
```

O resultado deve ser "305 Guardiões (275 ativos)". Voluntários, logins e a chave do CPF são preservados. Na demonstração, use e-mails `@example.com` e CPFs fictícios válidos, por exemplo `600.000.001-40`, `600.000.002-21` ou `600.000.003-02`.

## Operação depois da semana 10

Quem opera: a pessoa dedicada ao Clube (80 horas por mês, 70% aquisição e 30% retenção). Competência necessária: usar o painel e a Asaas; não exige programação.

| Frequência | Tarefa | Onde |
|---|---|---|
| Diária (10 min) | Aba **Alerta de churn**: contatar pelo WhatsApp os Guardiões de prioridade alta | Painel |
| Semanal | Registrar adesões presenciais; acompanhar **Canais** (o uso semanal também mantém o Supabase ativo) | Painel |
| Mensal | **Operação do mês**: gerar cobranças (só no MVP), enviar a notícia de impacto; conferir no extrato o Pix direto de quem ainda não migrou e marcar "Recebido no extrato" ou "Não recebido"; **Resumo**: baixar o CSV para a prestação de contas | Painel e extrato bancário |
| Jan a mar/2027 | Convidar cada Guardião da base atual a migrar para a Asaas; quem aceitar, botão **Migrar para Asaas** na aba Guardiões. Meta: 80% migrados (indicador "Base ainda em Pix direto" no Resumo) | Painel e WhatsApp |
| Trimestral | Rodar os testes; revisar parâmetros e comparar com o plano do business case | SQL Editor |

**Base atual (modelo híbrido, DT-15):** os Guardiões que já doam por Pix direto são cadastrados no painel marcando "Já doa por Pix direto" na adesão presencial. Não trocam a forma de pagar e recebem a mesma comunicação.

Parâmetros de negócio (metas, custeio de referência, taxas, limite de tentativas) ficam na tabela `parametro` e mudam sem mexer em código.

**Se o Supabase pausar:** entrar no painel do Supabase e clicar em *Restore project*. O projeto pode ser restaurado em até um ano, sem perda de dados. A rotina `manter_ativo.yml` evita a pausa.

**Se o banco for perdido:** recriar com os arquivos de `db/` (exceto o 05) e reimportar clientes, assinaturas e cobranças pela API da Asaas.

## Passagem para o Instituto

O projeto de demonstração foi criado na conta Supabase do grupo. Para a operação real:

1. O Instituto cria sua própria conta no Supabase, com e-mail institucional.
2. Transfere-se o projeto para a organização do Instituto (Supabase: *Project Settings > General > Transfer project*) ou recria-se o projeto seguindo a instalação acima, sem o arquivo 05.
3. A pessoa dedicada é cadastrada como voluntária (passos 3 e 4 da instalação).

## Passo para produção (fora do escopo do MVP)

Uma Edge Function do Supabase recebe o webhook da Asaas, valida o token configurado na Asaas e chama `fn_processar_evento` com a chave de serviço. A cobrança mensal passa a ser criada pela assinatura da Asaas (evento `PAYMENT_CREATED`), e `fn_gerar_cobrancas` e o simulador deixam de ser usados. A página de adesão passa a encaminhar para o checkout da Asaas. Em `web/config.js`, `demonstracao: false` esconde o aviso e o simulador. Detalhes em [DT-04](docs/decisoes_tecnicas.md).

## Dados e privacidade

- Dados sintéticos: nomes aleatórios, e-mails no domínio reservado `example.com`, telefones fictícios. Nenhum dado real de doador está neste repositório. O teste T20 verifica isso.
- Em produção: nome, CPF, e-mail, WhatsApp e registro do consentimento LGPD. Nenhum dado de cartão.
- **CPF cifrado:** o CPF é obrigatório e identifica o Guardião (decisão da semana 5; a Asaas também o exige). O banco guarda só a impressão digital HMAC-SHA256 com chave secreta: barra duplicidade e responde "este CPF já é Guardião?", mas não permite ler o número. O CPF completo fica só na Asaas. Detalhes em [DT-14](docs/decisoes_tecnicas.md).
- **Pendências de LGPD para operar com doadores reais** (política de privacidade, canal do titular, prazo de guarda, procedimento de exclusão, entre outras): [docs/lgpd_pendencias.md](docs/lgpd_pendencias.md).
- A interface não usa fotos de crianças, em linha com o Manual de Boas Práticas para Redes Sociais do Instituto.
- A página não promete dedução de Imposto de Renda: doação direta ao Instituto não é dedutível.
