# Principais decisões técnicas

Clube Guardiões do Começo | Instituto Ebenézer | registro atualizado em 28/09/2026 (CPF cifrado incluído na DT-14)

Cada decisão traz o contexto, a escolha, as alternativas descartadas e a consequência para quem vai operar a solução depois dos autores.

---

## DT-01. Gateway de pagamento: Asaas

**Contexto.** A semana 5 recomendou a Doare por critério técnico de funcionalidades. A análise financeira sobre o DRE 2025 e a proposta comercial de 09/09/2026 mostrou que a mensalidade de R$ 650 mais 5,30% por transação consumiria 28,9% da arrecadação recorrente atual.

**Decisão.** Construir sobre a Asaas, gateway que o Instituto já contratou. Sem mensalidade; R$ 1,99 por Pix recebido e R$ 0,55 por mensagem de WhatsApp da régua (tabela pública).

**Descartado.** Doare (custo fixo desproporcional ao porte); desenvolver gateway próprio (regulação financeira e segurança fora do alcance do Instituto).

**Consequência.** Perdem-se ferramentas de campanha (crowdfunding, rifa, embaixadores). A régua de relacionamento, o painel e o alerta de churn foram construídos no MVP. Reavaliar outra plataforma só se a base passar de 500 Guardiões e o Instituto precisar de recursos de campanha que o MVP não cobre.

## DT-02. Banco e API: Supabase (plano gratuito)

**Contexto.** O enunciado exige modelo de dados, dados sintéticos, testes e operação estável. A solução precisa ser operada pelo Instituto sem os autores e a custo zero.

**Decisão.** PostgreSQL no Supabase, plano gratuito, região São Paulo. A API é gerada pelo próprio Supabase a partir das tabelas, views e funções; não há servidor próprio para manter.

**Descartado.** Google Sheets com Apps Script: mais familiar ao Instituto, mas sem restrições de integridade no modelo de dados e com testes difíceis de automatizar e evidenciar.

**Consequência.** O plano gratuito pausa projetos com uma semana de baixa atividade no banco. O projeto pausado é restaurado pelo painel do Supabase em até um ano. Com a pessoa dedicada usando o painel semanalmente, o risco é baixo; como garantia, uma rotina gratuita consulta o banco a cada três dias (`.github/workflows/manter_ativo.yml`).

## DT-03. O fluxo principal mora no banco, em funções

**Decisão.** Adesão, cobrança mensal, pagamento, falha, recuperação, impacto e cancelamento são funções SQL (`db/02_funcoes.sql`). A interface só exibe as views e chama as funções.

**Por quê.** As regras de negócio ficam em um único lugar, testável de forma automatizada e independente da interface. Trocar a interface no futuro não exige reescrever regra nenhuma. Também é a garantia de segurança: nenhum usuário grava direto nas tabelas.

## DT-04. Integração com o gateway simulada no MVP

**Decisão.** No MVP, os avisos da Asaas são produzidos por `fn_simular_gateway` (o mês inteiro) ou pelos botões "Pix pago" e "Pix vencido" do painel (uma cobrança). Os dois caminhos chamam `fn_processar_evento`, a mesma função que o webhook real vai chamar.

**Por quê.** O enunciado pede dados sintéticos, o que admite simulação, e elimina a dependência de conta e chave de API em dez dias. Os eventos simulados usam os nomes reais da Asaas. Para Pix, a Asaas envia `PAYMENT_RECEIVED` (pagamento recebido) ou `PAYMENT_OVERDUE` (cobrança vencida), sem estado intermediário de confirmação.

**Passo para produção.** Uma Edge Function do Supabase recebe o webhook, valida o token de autenticação configurado na Asaas e chama `fn_processar_evento` com a chave de serviço. A chave de API da Asaas fica somente nesse endpoint, nunca na interface. A cobrança mensal passa a ser criada pela própria assinatura na Asaas (evento `PAYMENT_CREATED`); `fn_gerar_cobrancas` e o simulador deixam de ser usados. As demais funções permanecem iguais.

## DT-05. Idempotência do webhook

**Decisão.** Todo evento recebido é registrado em `evento_gateway` pelo seu identificador. Um evento repetido retorna `duplicado` e não produz efeito.

**Por quê.** Gateways podem reenviar o mesmo evento, e a documentação da Asaas orienta implementar idempotência. Sem isso, um reenvio duplicaria agradecimentos ou contaria pagamento duas vezes. Coberto pelo teste T07 e comprovado pelo controle negativo.

## DT-06. Regra de dados: a Asaas é a fonte da verdade

**Decisão.** O banco guarda uma cópia mínima e reconstruível. Nenhum dado de cartão. O CPF só entra cifrado (DT-14). Consentimento LGPD obrigatório na adesão, garantido por restrição do banco.

**Consequência.** Perder o banco não perde doador nem pagamento: a base é reconstruída pela API da Asaas, onde está o CPF completo.

## DT-07. Cancelamento automático após três falhas

**Decisão.** Três avisos de atraso para a mesma cobrança cancelam a assinatura por inadimplência. O limite está na tabela `parametro` e pode ser alterado pelo Instituto sem mexer em código.

**Por quê.** Evita cobrar indefinidamente quem deixou de doar e mantém a métrica de churn honesta. Antes disso, cada falha dispara o lembrete e coloca o Guardião no alerta de churn.

**Defeito encontrado e corrigido (28/09).** Um aviso de atraso que chegasse para uma assinatura já cancelada tentava cancelá-la de novo e gerava erro. Isso pode acontecer com o webhook real. Agora o aviso é ignorado sem erro; o teste T15 protege contra a volta do defeito.

## DT-08. Dados sintéticos gerados dentro do banco

**Decisão.** O gerador é uma função SQL (`fn_gerar_dados_sinteticos`, em `db/05_dados_sinteticos.sql`), com semente fixa, calibrada com os números do business case: 35 Guardiões iniciais (dado real), conversão de 30 doadores pontuais, 20 novos por mês e churn próximo de 2%.

**Por quê.** A primeira versão era um script Python que gerava um arquivo SQL de 1,4 MB, grande demais para colar no SQL Editor do Supabase. A função roda dentro do banco e o Instituto regenera a demonstração com um comando. A mesma semente produz a mesma base no Supabase e localmente (verificado: 305 Guardiões e 2.222 cobranças nos dois).

**Resultado verificado.** Ticket médio de R$ 76,73, churn médio de 1,55% ao mês e 275 Guardiões no mês 12, contra 267 projetados no modelo financeiro (teste T19).

**Proteções.** A função se recusa a rodar se a base já tiver dados ou se encontrar qualquer e-mail fora do domínio reservado `example.com` (T18), e não pode ser chamada pela API (S08).

## DT-09. Acesso ao painel por lista de voluntários

**Contexto.** No Supabase, qualquer pessoa pode criar uma conta pela API pública e passar a ter o papel "autenticado". Uma regra do tipo "autenticado lê tudo" exporia a base de doadores a quem criasse uma conta.

**Decisão.** Só lê dados e opera o fluxo quem tem login **e** está na tabela `voluntario`. A checagem é feita pelo banco, nas políticas de leitura e dentro de cada função do painel (`eh_voluntario`). O visitante anônimo lê apenas a lista de canais e só pode chamar a função de adesão pública.

**Verificado.** Anônimo não lê Guardiões nem executa funções do painel (S01, S02, S04); conta criada por terceiro, sem cadastro de voluntário, não vê nada (S05); voluntário cadastrado opera normalmente (S06); ninguém altera tabelas sem passar pelas funções (S07).

**Alertas da plataforma.** O verificador de segurança do Supabase avisa que funções com privilégio elevado estão expostas. É intencional: elas são a única porta de gravação e validam as regras. O aviso está registrado aqui para quem assumir a manutenção.

## DT-10. Página de adesão pública com função própria

**Decisão.** A página pública chama `fn_aderir_publico`, que fixa o Pix como meio de pagamento, usa a data do dia, limita o valor entre R$ 10 e R$ 5.000 e não devolve identificadores internos. O canal de origem vem do link (`?origem=qr`, `?origem=instagram`...), o que mede as horas de aquisição por canal.

**Em produção.** A adesão passa a acontecer no checkout da Asaas; esta função é substituída pelo registro do cliente vindo do webhook.

## DT-11. Interface sem etapa de build

**Decisão.** HTML, CSS e JavaScript puros, com a biblioteca oficial do Supabase (`supabase-js` 2.117.2) copiada para `web/vendor/`. Duas telas: `index.html` (adesão) e `painel.html` (voluntário).

**Por quê.** Qualquer pessoa com noções básicas de web consegue alterar um texto ou uma cor; hospedagem gratuita em qualquer serviço de arquivos estáticos; nenhuma dependência de ferramenta que envelhece. A biblioteca copiada garante que a tela não quebre se uma CDN mudar.

**Descartado.** React ou Next.js: mais produtivos para equipes de desenvolvimento, mas exigem build e manutenção de dependências que o Instituto não teria.

## DT-12. Testes que rodam no próprio Supabase

**Decisão.** As suítes são funções no esquema `qa` que devolvem o resultado como tabela e desfazem tudo ao final. Rodam igual no SQL Editor do Supabase e num PostgreSQL local, e são independentes de data: usam um mês futuro sem movimento.

**Por quê.** O Instituto consegue repetir os testes sem instalar nada. A evidência de teste no Supabase deixa de depender de ferramenta externa.

**Complemento.** O teste de interface usa uma réplica local com PostgREST, o mesmo motor de API do Supabase, e o navegador Chromium via Playwright (`tests/e2e/`).

## DT-13. O que não foi construído, de propósito

CRM próprio, motor de campanhas e sistema de embaixadores. Seriam sistemas que o Instituto não conseguiria manter sem os autores. A segmentação e o histórico de doador usam o que a Asaas já oferece.

## DT-14. CPF como identificador único, guardado cifrado

**Contexto.** A entrega da semana 5 definiu o CPF como campo obrigatório: é o melhor identificador único para evitar doador duplicado e para integrar um CRM no futuro. A Asaas também exige CPF para cadastrar o cliente e emitir cobrança. Uma versão intermediária deste MVP havia retirado o CPF por cautela com a LGPD, sem registrar que isso alterava uma decisão já entregue; esta decisão corrige isso.

**Decisão.** O CPF é obrigatório na adesão e identifica o Guardião. O banco do painel guarda apenas a impressão digital do CPF (HMAC-SHA256) calculada com uma chave secreta aleatória, gerada na instalação e guardada no esquema `privado`, sem acesso pela API. O número completo fica só na Asaas.

**Como funciona.** O mesmo CPF gera sempre o mesmo código. Isso permite:
- barrar a segunda adesão da mesma pessoa, mesmo com outro e-mail (T22);
- reconhecer o ex-Guardião que volta e preservar seu histórico (T12);
- responder ao voluntário se um CPF já é Guardião, sem revelar o número (T24, função `fn_consultar_cpf`).

O código não permite recuperar o número. Sem a chave, nem por força bruta: por isso não se usa um resumo simples (SHA-256 puro), que seria revertido testando os cerca de um bilhão de CPFs possíveis. O controle negativo 2 prova que a suíte detecta essa troca.

**Descartado.**
- CPF em texto aberto no banco: um vazamento exporia o CPF de todos os doadores de um banco operado por voluntários em plano gratuito.
- Criptografia reversível: permitiria ler o CPF de volta, o que o painel não precisa; quando for preciso o número (emitir recibo, cruzar com CRM), ele é consultado na Asaas pelo código do cliente.
- Sem CPF: contradiz a semana 5 e deixa passar duplicidades.

**LGPD.** É pseudonimização (art. 13, §4º): o dado continua sendo pessoal. A cifragem atende aos princípios de necessidade e segurança, mas a conformidade completa depende das pendências institucionais listadas em [lgpd_pendencias.md](lgpd_pendencias.md).

**Em produção.** O CPF passa a ser pedido no checkout da Asaas, e o banco recebe apenas a impressão digital calculada no registro do cliente. Recomenda-se mover a chave para o cofre do Supabase (Vault).

## DT-15. Base atual em modelo híbrido: Pix direto convive com a Asaas

**Contexto.** Os 35 Guardiões de hoje doam por Pix direto na conta do Instituto, fora da Asaas. Deixá-los de fora do sistema deixaria o painel sem a base inteira, sem régua, sem alerta de churn e sem prestação de contas unificada. Migrá-los à força arrisca perder justamente os doadores mais fiéis.

**Decisão.** Modelo híbrido, em duas camadas:
1. Todos entram no painel desde o primeiro dia (`fn_cadastrar_pix_direto`), com CPF e consentimento, no meio de pagamento `pix_direto` e origem "Base Pix manual". Recebem boas-vindas, notícia mensal de impacto e aparecem nas métricas.
2. A migração para a Asaas é ativa e voluntária: a pessoa dedicada convida cada Guardião; quem aceita é migrado em dois cliques (`fn_migrar_para_asaas`), mantendo valor, dia e histórico. Quem não migra tem o Pix conferido no extrato todo mês e registrado à mão (`fn_registrar_pix_direto`), pelo mesmo caminho do webhook: agradecimento, lembrete, alerta de churn e inadimplência funcionam igual. O rastro fica em `evento_gateway` com o prefixo `manual_`.

**Descartado.** Deixar a base de fora (painel incompleto, churn invisível); migração obrigatória (risco de perda de doadores fiéis).

**Consequência.** Para o doador, nada muda no bolso: continua pagando por Pix, sem taxa; a tarifa da Asaas (R$ 3,09 por Guardião ao mês) é do Instituto e já está no modelo financeiro para toda a base. Meta operacional: 80% da base atual migrada até março de 2027. Enquanto houver Pix direto, a conferência do extrato é tarefa mensal da pessoa dedicada. O simulador da Asaas ignora o Pix direto, porque a Asaas não o enxerga. Testes: T25 a T28, S11 e E18.

## DT-16. O MVP evolui o protótipo navegável da semana 5

**Contexto.** A primeira versão do MVP foi construída a partir do enunciado da semana 10 e da documentação do projeto, não das telas do protótipo V7.0. A navegação ficou diferente da entregue na semana 5: sem cadastro em etapas, sem tela de Pix, sem convite e sem a tela de Atividades da equipe.

**Decisão.** Reconstruir a jornada pública nas telas do protótipo (Início, Cadastro em 3 etapas, Pagamento Pix, Erro no Pix, Confirmação, Convite, Aviso de Privacidade) e trazer ao painel as telas da equipe que faltavam (Atividades e prestação de contas; Registrar contato feito), tudo sobre o banco real. O convite passa a ser rastreável (`codigo_convite`, `indicado_por`) e a notícia mensal de impacto leva o texto registrado por atividade (`atividade`, `impacto_mensal`), que passa a ser obrigatório antes do envio.

**Descartado nesta entrega.** Minha Área, login da Guardiã e recibo: exigem autenticação real da doadora (US06 da semana 5), que não cabe com segurança antes da banca. Ficam para a fase 2 sobre os mesmos dados.

**Consequência.** Cada tela da semana 5 tem destino registrado em `docs/rastreabilidade_semana5.md`. O visitante anônimo passa a poder descobrir só o primeiro nome de quem o convidou, e apenas com o código do link. Testes: T13, T16, T29 a T31, S12, E19 a E21.

