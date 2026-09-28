# Casos de teste e evidências

Clube Guardiões do Começo | Instituto Ebenézer | atualizado em 28/09/2026

Três camadas de teste, todas automatizadas:

| Camada | Onde roda | Quantidade | Resultado |
|---|---|---|---|
| Fluxo principal (banco) | Supabase e PostgreSQL local | 28 testes | 28 aprovados |
| Regras de acesso (banco) | Supabase e PostgreSQL local | 11 testes | 11 aprovados |
| Interface ponta a ponta | Chromium sobre réplica local do Supabase | 19 passos | 19 aprovados |

Mais dois **controles negativos**, que provam que os testes detectam defeitos.

## Como rodar

| Camada | Comando |
|---|---|
| Fluxo, no Supabase | `select * from qa.fn_rodar_testes();` no SQL Editor |
| Acesso, no Supabase | `select * from qa.fn_testes_seguranca();` no SQL Editor |
| Fluxo e acesso, local | `./tests/rodar_testes.sh` |
| Interface, local | `./tests/e2e/rodar_e2e.sh` |

Os testes do banco rodam num bloco desfeito ao final: não alteram os dados. Usam um mês futuro sem movimento e podem ser repetidos a qualquer momento.

## Cobertura do fluxo

| Etapa do fluxo | Slide 5 do deck | Banco | Interface |
|---|---|---|---|
| Adesão | Passo 1 | T01 a T04, T12, T16 | E01, E02, E03, E15 |
| CPF: validação, duplicidade, cifragem, consulta | Passo 1 | T21 a T24 | E01, E02, E03, E07b |
| Cobrança mensal | Passo 1 | T05 | E08 |
| Pix pago e agradecimento | Passo 2 | T06, T07, T17 | E09 |
| Notícia mensal de impacto | Passo 3 | T13 | E13 |
| Lembrete, recuperação e alerta de churn | Passo 4 | T08, T09 | E10, E11 |
| Cancelamento | Passo 4 | T10, T11, T15 | E12, E14 |
| Painel e prestação de contas | Slides 8, 9 e 11 | T14 | E05, E06, E07 |
| Qualidade e integridade dos dados | Handover | T18, T19, T20 | E17 |
| Acesso e privacidade | Handover | S01 a S11 | E04 |
| Base atual em Pix direto (modelo híbrido): cadastro, registro manual, migração para a Asaas | Slide 10, Fase 1 | T25 a T28 | E09, E18 |
| Uso no celular | Handover | | E16 |

## Fluxo principal (banco)

| ID | Cenário | Resultado esperado |
|---|---|---|
| T01 | Adesão com dados válidos e consentimento | Guardião criado, e-mail normalizado, assinatura ativa, boas-vindas |
| T02 | Adesão sem consentimento LGPD | Rejeitada |
| T03 | Adesão com e-mail inválido | Rejeitada |
| T04 | Segunda adesão do mesmo CPF com assinatura ainda ativa | Rejeitada |
| T05 | Gerar cobranças do mês duas vezes | Uma cobrança por Guardião ativo, sem duplicar, no dia escolhido |
| T06 | Pix pago | Cobrança paga, agradecimento enviado |
| T07 | O mesmo aviso de pagamento chega de novo | Nenhum efeito adicional (idempotência) |
| T08 | Pix vencido | Status falhou, tentativa contada, lembrete enviado, Guardião no alerta de churn |
| T09 | Pagamento depois do lembrete | Cobrança recuperada, Guardião sai do alerta |
| T10 | Três avisos de atraso | Assinatura cancelada por inadimplência |
| T11 | Cancelamento a pedido | Cobrança pendente cancelada, sem novas cobranças, confirmação enviada |
| T12 | Ex-Guardião volta com o mesmo e-mail | Nova assinatura, histórico preservado |
| T13 | Enviar a notícia de impacto duas vezes no mês | Uma mensagem por Guardião ativo |
| T14 | Conferência do painel | Receita e contagem de ativos batem com os lançamentos |
| T15 | Aviso de atraso para assinatura já cancelada (regressão) | Ignorado, sem erro |
| T16 | Adesão pela página pública | Registra o canal de origem; recusa valor fora do limite |
| T17 | Simulador do gateway no mês inteiro | Nenhuma cobrança da Asaas fica pendente; um aviso por cobrança, pelo caminho do webhook |
| T18 | Gerador sobre base já populada | Recusa rodar |
| T19 | Calibração dos dados sintéticos | Ticket entre R$ 70 e R$ 90, churn entre 1% e 4%, base a até 15% do plano |
| T20 | Integridade | Uma assinatura ativa por Guardião, um CPF por Guardião, todo pagamento com aviso do gateway, nenhum e-mail real |
| T21 | CPF com dígito verificador errado, com números repetidos ou curto | Recusado |
| T22 | Mesmo CPF com outro e-mail; mesmo e-mail com outro CPF | Os dois recusados; nenhum Guardião duplicado |
| T23 | Como o CPF fica guardado | Nunca em texto aberto; só impressão digital com chave secreta (não é SHA-256 simples) |
| T24 | Voluntário consulta um CPF | Encontra o Guardião cadastrado; CPF não cadastrado retorna vazio |
| T25 | Guardião da base cadastrado em Pix direto | Entra com CPF, consentimento e origem "Base Pix manual", sem trocar a forma de pagar; sem consentimento é recusado |
| T26 | Mês de um Guardião em Pix direto | O simulador da Asaas não o processa; o registro manual paga, envia agradecimento e deixa rastro `manual_`; cobrança da Asaas recusa registro manual |
| T27 | Pix direto não recebido no mês | Lembrete registrado e Guardião no alerta de churn |
| T28 | Migração para a Asaas | Valor e histórico mantidos; não se repete; a cobrança seguinte passa pela Asaas |

## Regras de acesso (banco)

| ID | Cenário | Resultado esperado |
|---|---|---|
| S01 | Visitante anônimo consulta dados | Lê só a lista de canais; Guardiões bloqueados |
| S02 | Anônimo chama função do painel | Bloqueado |
| S03 | Anônimo adere pela página pública | Permitido |
| S04 | Anônimo grava direto na tabela | Bloqueado |
| S05 | Pessoa cria conta mas não é voluntária | Não vê dados nem executa o fluxo |
| S06 | Voluntário cadastrado | Lê o painel e executa o fluxo |
| S07 | Voluntário altera tabela sem passar pelas funções | Bloqueado |
| S08 | Chamar o gerador de dados sintéticos pela API | Bloqueado |
| S09 | Anônimo consulta CPF | Bloqueado |
| S10 | Voluntário tenta ler o CPF cifrado, a chave ou calcular impressões digitais | Bloqueado nos três casos |
| S11 | Anônimo ou conta sem cadastro de voluntário tenta cadastrar a base, registrar Pix direto ou migrar | Bloqueado |

## Interface ponta a ponta

| ID | Passo | Resultado esperado |
|---|---|---|
| E01 | Enviar a adesão sem nome, com CPF inválido e sem consentimento | Mensagens de validação; CPF formatado enquanto digita |
| E02 | Aderir pelo link do QR Code com valor livre de R$ 150 | Guardião gravado com valor, dia e canal QR Code; CPF só cifrado |
| E03 | Mesmo CPF com outro e-mail; mesmo e-mail com outro CPF | Os dois recusados com mensagem clara |
| E04 | Entrar com senha errada e com conta não voluntária | Acesso negado nos dois casos |
| E05 | Entrar como voluntário | Resumo com o mesmo número de ativos do banco |
| E06 | Baixar o CSV de métricas | 12 meses para a prestação de contas |
| E07 | Buscar a nova Guardiã e abrir o histórico | Mostra a mensagem de boas-vindas |
| E07b | Consultar um CPF no painel | Encontra a Guardiã; CPF não cadastrado retorna "nenhum" |
| E08 | Gerar cobranças de out/2026 duas vezes | 276 criadas, segunda vez não duplica |
| E09 | Simular a Asaas no mês | Todas processadas; nenhuma pendente |
| E10 | Abrir o alerta de churn | Lista com prioridade e link de WhatsApp pronto |
| E11 | Marcar "Pix pago" numa cobrança em atraso | Vira recuperada e sai do alerta |
| E12 | Três avisos de atraso na mesma cobrança | Cancelada por inadimplência; simulação encerrada para ela |
| E13 | Enviar a notícia de impacto duas vezes | Segunda vez não duplica |
| E14 | Cancelar a pedido | Exige confirmação e registra o motivo |
| E15 | Voluntário registra adesão presencial | Aparece no canal da campanha |
| E16 | Abrir a adesão no celular | Cabe na tela, sem rolagem lateral |
| E17 | Todo o roteiro | Nenhum erro de JavaScript no console |
| E18 | Cadastrar Guardião da base em Pix direto, registrar o Pix do mês pelo extrato e migrar para a Asaas | Canal fixo em "Base Pix manual"; pagamento com rastro manual; migração em dois cliques |

## Controles negativos

1. A idempotência do webhook foi deliberadamente quebrada numa cópia do banco. A suíte parou no T07 com "evento repetido não foi detectado".
2. A cifragem do CPF foi trocada por um SHA-256 simples, sem chave. A suíte parou no T23 com "cpf_hash sem chave secreta".

Um teste que nunca falha não prova nada; estes provam.

## Defeitos encontrados pelos testes

| Data | Defeito | Correção | Teste que protege |
|---|---|---|---|
| 28/09 | Aviso de atraso para assinatura já cancelada gerava erro | Aviso passa a ser ignorado | T15 |
| 28/09 | Qualquer conta criada no Supabase leria a base de doadores | Acesso restrito à tabela de voluntários | S05 |
| 28/09 | Tabela do mês podia mostrar resultado de filtro antigo ao trocar o filtro rápido | Só a consulta mais recente desenha a tabela | E12 |
| 28/09 | Botões de simulação apareciam para cobranças de assinatura encerrada | Botões ocultos; aviso "assinatura encerrada" | E12 |
| 28/09 | O próprio teste E11 lia o nome da cobrança antes de o filtro "Falhou" ser aplicado e registrava o Guardião errado no log | O teste espera o filtro antes de ler a linha | E11 |

## Evidências

| Arquivo | Conteúdo |
|---|---|
| `evidencias/testes_supabase_2026-09-28.log` | Primeira execução no Supabase: 24 de fluxo e 10 de acesso aprovados |
| `evidencias/testes_local_2026-09-28_1612.log` | Mesma execução em PostgreSQL 16 local |
| `evidencias/testes_supabase_2026-09-28_modelo_hibrido.log` | Execução no Supabase depois do modelo híbrido: 28 de fluxo e 11 de acesso aprovados |
| `evidencias/testes_local_2026-09-28_1933.log` | Mesma execução em PostgreSQL 16 local |
| `evidencias/controle_negativo_2026-09-28.log` | Os dois controles negativos |
| `evidencias/e2e/resultado_e2e.log` | Os 19 passos de interface aprovados |
| `evidencias/e2e/*.png` | Capturas de tela de cada tela do roteiro |
