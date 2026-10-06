# Casos de teste e evidências

Clube Guardiões do Futuro | Instituto Ebenézer | MVP funcional, semana 10

Três camadas de teste, todas automatizadas:

| Camada | Onde roda | Quantidade | Resultado |
|---|---|---|---|
| Fluxo principal (banco) | Supabase e PostgreSQL local | 39 testes | 39 aprovados |
| Regras de acesso (banco) | Supabase e PostgreSQL local | 13 testes | 13 aprovados |
| Interface ponta a ponta | Chromium sobre réplica local do Supabase | 25 passos | 25 aprovados |

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
| Adesão (Guardião R$ 85, e-mail opcional) | Passo 1 | T01 a T04, T12, T16, T32 | E01, E02, E03, E15 |
| CPF: validação, duplicidade, cifragem, consulta | Passo 1 | T21 a T24 | E01, E02, E03, E07b |
| Cobrança mensal | Passo 1 | T05 | E08 |
| Pix pago e agradecimento | Passo 2 | T06, T07, T17 | E09 |
| Notícia mensal de impacto | Passo 3 | T13 | E13 |
| Lembrete, recuperação e alerta de churn | Passo 4 | T08, T09 | E10, E11 |
| Cancelamento | Passo 4 | T10, T11, T15 | E12, E14 |
| Painel e prestação de contas | Slides 8, 9 e 11 | T14 | E05, E06, E07 |
| Qualidade e integridade dos dados | Handover | T18, T19, T20 | E17 |
| Acesso e privacidade | Handover | S01 a S13 | E04 |
| Base atual em Pix direto (modelo híbrido): cadastro, registro manual, migração para a Asaas | Slide 10, Fase 1 | T25 a T28 | E09, E18 |
| Jornada da semana 5: Pix, erro, confirmação, convite rastreável, Aviso de Privacidade | Slide 5, Passos 1 e 2 | T16, T29 | E19 |
| Prestação de contas por atividade (tela Atividades da semana 5) | Slide 5, Passo 3 | T13, T30 | E20 |
| Contato pessoal com quem está em atraso (tela Lembretes da semana 5) | Slide 5, Passo 4 | T31 | E21 |
| Doação única de qualquer valor e "Indique um novo Doador" | Slide 5, Passos 1 e 2 | T29, T33, S13 | E19, E22 |
| Pausa em vez de cancelamento | Slide 5, Passo 4 | T34, T36 | E23, E24 |
| Minha Área: entrar, status, histórico, impacto, pausar, cancelar, reativar, recibo anual | Slide 5, Passos 3 e 4 | T35, T36, T38, S13 | E23 |
| Estrelas e níveis de Guardião | Slide 5, Passo 3 | T37 | E23, E24 |
| Painel: doações únicas, pausados, nível e ações de pausa | Slides 8, 9 e 11 | T14, T34 | E05, E24 |
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
| T16 | Adesão pela página pública | Registra o canal de origem; o Guardião doa R$ 85 por mês; valor mensal de R$ 60 é recusado |
| T17 | Simulador do gateway no mês inteiro | Nenhuma cobrança da Asaas fica pendente; um aviso por cobrança, pelo caminho do webhook |
| T18 | Gerador sobre base já populada | Recusa rodar |
| T19 | Calibração dos dados sintéticos | Ticket entre R$ 70 e R$ 90, churn entre 1% e 4%, base de demonstração ao menos igual à do plano em fases no mês 12 (a partir de 140; plano: 164) |
| T20 | Integridade | Uma assinatura ativa por Guardião, um CPF por Guardião, todo pagamento com aviso do gateway, nenhum e-mail real |
| T21 | CPF com dígito verificador errado, com números repetidos ou curto | Recusado |
| T22 | Mesmo CPF com outro e-mail; mesmo e-mail com outro CPF | Os dois recusados; nenhum Guardião duplicado |
| T23 | Como o CPF fica guardado | Nunca em texto aberto; só impressão digital com chave secreta (não é SHA-256 simples) |
| T24 | Voluntário consulta um CPF | Encontra o Guardião cadastrado; CPF não cadastrado retorna vazio |
| T25 | Guardião da base cadastrado em Pix direto | Entra com CPF, consentimento e origem "Base Pix manual", sem trocar a forma de pagar; sem consentimento é recusado |
| T26 | Mês de um Guardião em Pix direto | O simulador da Asaas não o processa; o registro manual paga, envia agradecimento e deixa rastro `manual_`; cobrança da Asaas recusa registro manual |
| T27 | Pix direto não recebido no mês | Lembrete registrado e Guardião no alerta de churn |
| T28 | Migração para a Asaas | Valor e histórico mantidos; não se repete; a cobrança seguinte passa pela Asaas |
| T29 | Adesão pelo link pessoal de convite de um Guardião | Registra quem convidou e o canal "Indicação de Guardião"; código inválido é ignorado |
| T30 | Equipe registra o que cada atividade sustentou no mês | Texto atualizado sem duplicar; texto curto recusado; a notícia do mês leva o texto |
| T31 | Equipe registra o contato feito com quem está em atraso | Contato com anotação no histórico; alerta mostra o último contato |
| T32 | E-mail é opcional; se informado, precisa ser válido | Guardião sem e-mail aceito; e-mail informado e inválido recusado |
| T33 | Doação única aceita qualquer valor a partir de R$ 10, é confirmada uma vez e gera link de convite | Fica pendente até a confirmação; confirmar de novo não tem efeito; link só vale depois de paga e registra a indicação; abaixo de R$ 10 ou sem consentimento é recusada |
| T34 | Pausa de 1 a 3 meses cancela o mês em aberto, não cobra durante a pausa e volta sozinha | Data de volta correta; nenhuma cobrança durante a pausa; painel mostra "pausado"; volta no mês indicado com mensagens de pausa e retomada; pausa acima de 3 meses recusada |
| T35 | Minha Área abre só com WhatsApp e CPF do Guardião, sem expor dados, e bloqueia após 5 erros | Devolve só os dados certos; WhatsApp errado não entra; tentativas repetidas bloqueadas |
| T36 | Pela Minha Área a Guardiã pausa, retoma, cancela com motivo e reativa | Status muda em cada ação; motivo registrado; reativação como Guardião de R$ 85 |
| T37 | 1ª estrela na primeira doação e uma a cada 3 meses (Ouro em 12); Bronze, Prata e Ouro | Níveis de `fn_nivel` corretos; nenhum Guardião com estrelas fora da regra ou acima de 5; quem tem 1 mês pago tem 1 estrela e quem tem 12 é Ouro |
| T38 | Recibo anual soma as doações pagas e só sai para o próprio Guardião | Total confere com as doações pagas no ano; CPF de outra pessoa não emite recibo |
| T39 | Demonstração recusa e-mail real (só @example.com ou em branco); em produção o e-mail comum é aceito | Adesão e doação única com e-mail real são recusadas e nada é gravado; com `modo_demonstracao = 0` o mesmo e-mail é aceito |

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
| S12 | Anônimo resolve um link de convite; tenta ler a prestação de contas, registrar impacto ou contato | Vê só o primeiro nome de quem convidou; o resto é bloqueado |
| S13 | Anônimo faz doação única e entra na Minha Área só com WhatsApp e CPF corretos; não lê doações nem pausa pelo painel. Voluntário lê as doações únicas sem o CPF cifrado | Doação única permitida; Minha Área recusa quem não é Guardião e WhatsApp que não confere; leitura de `doacao_unica` e `tentativa_acesso`, pausa pelo painel e confirmação pelo caminho do webhook bloqueadas; voluntário lê `vw_doacoes_unicas`, mas não o CPF cifrado |

## Interface ponta a ponta

| ID | Passo | Resultado esperado |
|---|---|---|
| E01 | Formulário valida nome, CPF (dígito verificador, com máscara) e exige consentimento LGPD | Mensagens de validação; CPF formatado enquanto digita |
| E02 | Aderir pelo link do QR Code como Guardião | Guardião de R$ 85 por mês gravado com dia e canal QR Code; CPF só cifrado |
| E03 | Mesmo CPF com outro e-mail; mesmo e-mail com outro CPF | Os dois recusados com mensagem clara |
| E04 | Entrar com senha errada e com conta não voluntária | Acesso negado nos dois casos |
| E05 | Entrar como voluntário | Resumo mostra Guardiões no Clube (ativos e pausados), igual ao banco |
| E06 | Baixar o CSV de métricas | 12 meses para a prestação de contas |
| E07 | Buscar a nova Guardiã e abrir o histórico | Mostra a mensagem de boas-vindas |
| E07b | Consultar um CPF no painel | Encontra a Guardiã; CPF não cadastrado retorna "nenhum" |
| E08 | Gerar cobranças de out/2026 duas vezes | 273 criadas, segunda vez não duplica |
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
| E19 | Jornada da semana 5: Pix com QR e copia e cola, falha e nova tentativa, confirmação em 3 etapas, "Indique um novo Doador" pelo WhatsApp, link pessoal que registra quem convidou, e-mail opcional, Aviso de Privacidade | Etapas 1 a 3 marcadas; mensagem de WhatsApp com o link do Guardião; indicação gravada; adesão sem e-mail aceita |
| E20 | Tentar enviar a notícia sem prestação de contas; registrar o texto de cada atividade | Envio recusado até o registro; prévia da notícia com as três atividades |
| E21 | Registrar contato feito no alerta de churn | Anotação gravada; alerta mostra o último contato |
| E22 | Doação única de qualquer valor (R$ 250), sem ser recorrente e sem e-mail, com "Indique um novo Doador" ao final | Pix de R$ 250,00 identificado como doação única, sem dia de pagamento; doação gravada como paga, sem e-mail, com o canal Instagram; botão de indicação abre o WhatsApp com o link pessoal |
| E23 | Minha Área: entra só com WhatsApp e CPF certos; mostra nível, estrelas, impacto e histórico; pausa, retoma, cancela com motivo, reativa por R$ 85 e emite o recibo | CPF errado não entra; cada ação muda o status; motivo do cancelamento gravado; reativação por R$ 85,00; recibo diz "sem dedução de Imposto de Renda" |
| E24 | Painel mostra doações únicas, Guardiões pausados com a data de volta, nível e estrelas; equipe pausa e retoma a pedido | 9 indicadores; aba Doações únicas com a doação paga; filtro "pausado" mostra a data de volta; Pausar 1 mês (com confirmação) e Retomar funcionando |

## Controles negativos

1. A idempotência do webhook foi deliberadamente quebrada numa cópia do banco. A suíte parou no T07 com "evento repetido não foi detectado".
2. A cifragem do CPF foi trocada por um SHA-256 simples, sem chave. A suíte parou no T23 com "cpf_hash sem chave secreta".

Um teste que nunca falha não prova nada; estes provam.

## Defeitos encontrados pelos testes

| Defeito | Correção | Teste que protege |
|---|---|---|
| Aviso de atraso para assinatura já cancelada gerava erro | Aviso passa a ser ignorado | T15 |
| Qualquer conta criada no Supabase leria a base de doadores | Acesso restrito à tabela de voluntários | S05 |
| Tabela do mês podia mostrar resultado de filtro antigo ao trocar o filtro rápido | Só a consulta mais recente desenha a tabela | E12 |
| Botões de simulação apareciam para cobranças de assinatura encerrada | Botões ocultos; aviso "assinatura encerrada" | E12 |
| O próprio teste E11 lia o nome da cobrança antes de o filtro "Falhou" ser aplicado e registrava o Guardião errado no log | O teste espera o filtro antes de ler a linha | E11 |

## Evidências

| Arquivo | Conteúdo |
|---|---|
| `evidencias/testes_local_2026-09-30_1337.log` | Execução em PostgreSQL local: 39 de 39 testes de fluxo e 13 de 13 de acesso |
| `evidencias/testes_supabase_2026-09-30_plano_em_fases.log` | Mesma execução no Supabase, com resultado idêntico ao local |
| `evidencias/testes_supabase_2026-09-29_trava_demonstracao.log` | Execução no Supabase que comprova a trava de e-mail da demonstração (T39) |
| `evidencias/controle_negativo_2026-09-28.log` | Os dois controles negativos |
| `evidencias/e2e/resultado_e2e.log` | Os 25 passos de interface aprovados (E01 a E24, com E07b) |
| `evidencias/e2e/*.png` | Capturas de tela de cada tela do roteiro |
