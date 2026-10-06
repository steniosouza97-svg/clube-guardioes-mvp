# Clube Guardiões do Futuro | MVP funcional

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

O que o MVP faz:

- **Guardião do Futuro:** doação mensal de R$ 85 por Pix, recorrente (parâmetro `valor_guardiao`). Guardiões da base atual mantêm o valor que já doam; R$ 85 vale para novas adesões e reativações.
- **Doação única:** qualquer pessoa doa uma vez, de qualquer valor (referências de R$ 30, R$ 60, R$ 120 ou outro; mínimo técnico de R$ 10).
- **Cadastro:** nome, WhatsApp e CPF obrigatórios; e-mail opcional (se informado, precisa ser válido). CPF guardado só cifrado.
- **Minha Área:** o Guardião entra com WhatsApp e CPF e vê status, nível com estrelas, linha do tempo de impacto, histórico e recibo anual; pode pausar, retomar, cancelar com motivo ou reativar.
- **Pausa em vez de cancelar:** de 1 a 3 meses, sem cobrança no período; a doação volta sozinha no mês escolhido.
- **Estrelas:** a 1ª na primeira doação paga e mais uma a cada 3 meses: 3 estrelas aos 6 meses = Bronze (a 2 do Ouro), 4 aos 9 = Prata (a 1 do Ouro), 5 aos 12 = Guardião do Futuro Ouro.
- **Indique um novo Doador:** depois de doar, a pessoa compartilha pelo WhatsApp uma mensagem de impacto com link pessoal; o painel conta as indicações.
- **Painel do voluntário:** 9 indicadores (inclui Guardiões pausados e doações únicas do mês), aba de doações únicas, nível de cada Guardião, pausar e retomar a pedido.

O pagamento real acontece na **Asaas**, gateway que o Instituto já contratou. No MVP, os avisos da Asaas são simulados com os nomes reais dos eventos (`PAYMENT_RECEIVED`, `PAYMENT_OVERDUE`) e passam pela mesma função que o webhook real vai chamar. O banco guarda uma cópia mínima e reconstruível; a Asaas é a fonte da verdade.

## Ambiente de demonstração

| Item | Valor |
|---|---|
| Banco e API | Supabase, projeto `clube-guardioes`, região São Paulo, plano gratuito |
| Endereço da API | `https://fakihzzncafuqtgxnqbi.supabase.co` |
| Repositório | https://github.com/steniosouza97-svg/clube-guardioes-mvp |
| Página de adesão (jornada da doadora, telas da semana 5) | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html |
| Dados | 305 Guardiões sintéticos (271 ativos, 4 pausados), 2.222 cobranças e 48 doações únicas, 12 meses de operação simulada (out/2025 a set/2026) |
| Migrações aplicadas no Supabase | 32, versionadas no histórico do projeto |

## Estrutura

| Pasta | Conteúdo |
|---|---|
| `db/` | Esquema, funções do fluxo, views de métricas, dados de referência, gerador de dados sintéticos e regras de acesso |
| `web/` | Interface: página pública (Guardião, doação única, Minha Área, recibo, Aviso de Privacidade) e painel do voluntário. HTML, CSS e JavaScript sem etapa de build |
| `tests/` | Suítes de teste do banco (`qa_*.sql`) e teste ponta a ponta da interface (`e2e/`) |
| `evidencias/` | Resultados das execuções: local, Supabase, controle negativo e capturas de tela |
| `docs/` | Modelo de dados, desenho do banco, decisões técnicas, casos de teste, teste com usuários e roteiro do vídeo |
| `.github/workflows/` | Rotina que impede a pausa do Supabase gratuito |

Documentação de handover:

- [Da semana 5 à semana 10: rastreabilidade do protótipo ao MVP](docs/rastreabilidade_semana5.md)
- [Modelo de dados](docs/modelo_de_dados.md)
- [Principais decisões técnicas](docs/decisoes_tecnicas.md)
- [Casos de teste e evidências](docs/casos_de_teste.md)
- [Roteiro do vídeo demonstrativo](docs/roteiro_video.md)
- [Privacidade e LGPD: feito e pendências](docs/lgpd_pendencias.md)
- [User stories e critérios de aceite](docs/user_stories.md)
- [Teste com usuários reais](docs/teste_com_usuarios.md)
- [Desenho do banco de dados (PDF)](docs/diagramas/diagrama_banco_de_dados.pdf)
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
select * from qa.fn_rodar_testes();       -- 39 testes do fluxo (T01 a T39)
select * from qa.fn_testes_seguranca();   -- 13 testes de acesso (S01 a S13)
```

Cada linha traz `PASS`, `INFO` ou `FALHA`. Os testes rodam num bloco desfeito ao final: nenhum dado é alterado. Usam um mês futuro sem movimento, então podem ser repetidos a qualquer momento, inclusive depois da demonstração.

**Localmente (PostgreSQL 14+):**

```bash
export PGHOST=localhost PGPORT=5432 PGUSER=postgres
./tests/rodar_testes.sh              # recria o banco, carrega tudo e roda as duas suítes
```

**Interface, ponta a ponta (local):** `tests/e2e/rodar_e2e.sh` sobe o banco com o PostgREST (o mesmo motor de API do Supabase) e percorre 25 passos no navegador com Playwright (E01 a E24, com E07b): jornada da semana 5 (cadastro em 3 etapas, Pix, falha e nova tentativa, confirmação, Indique um novo Doador), doação única sem e-mail, Minha Área completa (nível, estrelas, impacto, histórico, pausa, retomada, cancelamento com motivo, reativação por R$ 85, recibo), consulta de CPF, login, resumo, exportação, operação do mês, alerta, recuperação, inadimplência, cancelamento, doações únicas e pausados no painel, celular e console sem erros. Gera capturas em `evidencias/e2e/`. Com a réplica no ar, `tests/e2e/telas_responsivas.py` confere as telas principais em celular, tablet e computador e gera as capturas em `evidencias/responsivo/`.

Evidências: 39 de 39 testes do fluxo e 13 de 13 de acesso no Supabase e localmente, 25 de 25 passos de interface, e dois controles negativos que provam que a suíte detecta defeitos (idempotência do webhook e cifragem do CPF). Arquivos: `evidencias/testes_local_2026-09-30_1337.log`, `evidencias/testes_supabase_2026-09-30_plano_em_fases.log` e `evidencias/e2e/resultado_e2e.log`.

**Testar a Minha Área:** na página pública, clicar em **Minha Área** no topo e depois em **Entrar como Guardião de demonstração**. Ou digitar os dados do Guardião sintético Carlos Barbosa: WhatsApp `(11) 90000-0040` e CPF `800.000.040-73` (fictício). Ele aparece como Guardião Prata (4 estrelas, 11 meses), a 1 estrela do Ouro, impacto, histórico e recibo. Cinco tentativas erradas em 15 minutos bloqueiam a entrada por esse WhatsApp.

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
truncate evento_gateway, comunicacao, cobranca, assinatura, doacao_unica, tentativa_acesso, impacto_mensal, guardiao restart identity;
select fn_gerar_dados_sinteticos();
```

O resultado deve ser "305 Guardiões (271 ativos, 4 pausados)", com 48 doações únicas. Voluntários, logins e a chave do CPF são preservados. Na demonstração, o e-mail é opcional; se preencher, use `@example.com`. Use CPFs fictícios válidos, por exemplo `600.000.001-40`, `600.000.002-21` ou `600.000.003-02`.

## Operação depois da semana 10

Quem opera: a pessoa dedicada ao Clube. Competência necessária: usar o painel e a Asaas; não exige programação. O plano de captação cresce em três fases, conforme o modelo financeiro do business case:

| Fase | Período | Horas por mês | Captação / retenção | Novos Guardiões por mês | Churn esperado |
|---|---|---|---|---|---|
| 1. Implantação e ajuste | fev a jul/2027 | 80 | 56 h / 24 h | 5 a 10, mais 5 pontuais convertidos | até 3% |
| 2. Tração | ago/2027 a jul/2028 | 80 | 56 h / 24 h | 12 a 15 | até 2,5% |
| 3. Maturidade | ago/2028 a jan/2030 | 120 (segundo voluntário de 40 h, focado em retenção) | 72 h / 48 h | 18 | até 2% |

Passagem de fase: da 1 para a 2, 40 pontuais contatados, 80% dos 35 migrados para a Asaas e churn até 3%; da 2 para a 3, pelo menos 12 novos por mês em 3 meses seguidos e base acima de 200. Gatilhos de revisão: churn acima de 4% ao mês, base abaixo de 130 Guardiões no mês 12 (jan/2028) e custo de notificação acima de R$ 300 por mês. Os números de acompanhamento estão no **Resumo** e em **Canais** do painel.

| Frequência | Tarefa | Onde |
|---|---|---|
| Diária (10 min) | Aba **Alerta de churn**: contatar pelo WhatsApp os Guardiões de prioridade alta e clicar em **Registrar contato**. Pedido de pausa por WhatsApp: botão **Pausar 1 mês** na aba Guardiões (ou **Retomar**) | Painel |
| Semanal | Registrar adesões presenciais; acompanhar **Canais** (o uso semanal também mantém o Supabase ativo) | Painel |
| Mensal | **Doações únicas**: acompanhar a aba e convidar quem doou a virar Guardião. **Atividades**: registrar o que cada atividade sustentou no mês. **Operação do mês**: gerar cobranças (só no MVP), enviar a notícia de impacto; conferir no extrato o Pix direto de quem ainda não migrou e marcar "Recebido no extrato" ou "Não recebido"; **Resumo**: baixar o CSV para a prestação de contas | Painel e extrato bancário |
| Jan a mar/2027 | Convidar cada Guardião da base atual a migrar para a Asaas; quem aceitar, botão **Migrar para Asaas** na aba Guardiões. Meta: 80% migrados (indicador "Base ainda em Pix direto" no Resumo) | Painel e WhatsApp |
| Mensal | Comparar novos Guardiões e churn do mês com a curva da fase (tabela acima) | Painel, aba Resumo |
| Trimestral | Rodar os testes; revisar parâmetros e decidir a passagem de fase com a diretoria | SQL Editor e painel |

**Base atual (modelo híbrido, DT-15):** os Guardiões que já doam por Pix direto são cadastrados no painel marcando "Já doa por Pix direto" na adesão presencial. Não trocam a forma de pagar e recebem a mesma comunicação.

Parâmetros de negócio (valor do Guardião, pausa máxima, meses por estrela, metas, custeio de referência, taxas, limite de tentativas) ficam na tabela `parametro` e mudam sem mexer em código.

**Se o Supabase pausar:** entrar no painel do Supabase e clicar em *Restore project*. O projeto pode ser restaurado em até um ano, sem perda de dados. A rotina `manter_ativo.yml` reduz o risco de pausa, mas não o elimina: confira o projeto antes de cada demonstração.

**Se o banco for perdido:** recriar com os arquivos de `db/` (exceto o 05) e reimportar clientes, assinaturas e cobranças pela API da Asaas.

## Passagem para o Instituto

O projeto de demonstração foi criado na conta Supabase do grupo. Para a operação real:

1. O Instituto cria sua própria conta no Supabase, com e-mail institucional.
2. Transfere-se o projeto para a organização do Instituto (Supabase: *Project Settings > General > Transfer project*) ou recria-se o projeto seguindo a instalação acima, sem o arquivo 05.
3. A pessoa dedicada é cadastrada como voluntária (passos 3 e 4 da instalação).

## Passo para produção (fora do escopo do MVP)

Uma Edge Function do Supabase recebe o webhook da Asaas, valida o token configurado na Asaas e chama `fn_processar_evento` com a chave de serviço. A cobrança mensal passa a ser criada pela assinatura da Asaas (evento `PAYMENT_CREATED`), e `fn_gerar_cobrancas` e o simulador deixam de ser usados. A página de adesão passa a encaminhar para o checkout da Asaas, e a doação única é confirmada pelo webhook (`fn_processar_doacao_unica`). Em `web/config.js`, `demonstracao: false` esconde o aviso, o simulador e o Guardião de demonstração; no banco, `parametro.modo_demonstracao = 0` desliga a confirmação de doação sem a Asaas. A entrada na Minha Área por WhatsApp e CPF deve ser trocada por código de uso único enviado ao WhatsApp (ou link mágico por e-mail) antes de operar com doadores reais. Detalhes em [DT-04](docs/decisoes_tecnicas.md).

## Dados e privacidade

- Dados sintéticos: nomes aleatórios, e-mails no domínio reservado `example.com`, telefones fictícios. Nenhum dado real de doador está neste repositório. O teste T20 verifica isso.
- Em produção: nome, CPF, WhatsApp, e-mail (opcional) e registro do consentimento LGPD. Nenhum dado de cartão.
- **CPF cifrado:** o CPF é obrigatório e identifica o Guardião (decisão da semana 5; a Asaas também o exige). O banco guarda só a impressão digital HMAC-SHA256 com chave secreta: barra duplicidade e responde "este CPF já é Guardião?", mas não permite ler o número. O CPF completo fica só na Asaas. Detalhes em [DT-14](docs/decisoes_tecnicas.md).
- **Pendências de LGPD para operar com doadores reais** (política de privacidade, canal do titular, prazo de guarda, procedimento de exclusão, entre outras): [docs/lgpd_pendencias.md](docs/lgpd_pendencias.md).
- Identidade visual da entrega da semana 5 (verde do Instituto, logo da árvore e a mesma foto de atividade). A foto faz parte do banco de imagens liberado pelo Instituto para uso conforme sua política e o Manual de Boas Práticas para Redes Sociais. Qualquer foto nova de criança precisa da mesma liberação.
- A página e o recibo não prometem dedução de Imposto de Renda: doação direta ao Instituto não é dedutível para pessoa física, e o recibo diz isso.
