# User stories e critérios de aceite

Clube Guardiões do Começo | Instituto Ebenézer | atualizado em 28/09/2026

As user stories US01 a US03 da semana 5 foram escritas para o fluxo de adesão de uma plataforma completa (Doare). Com a decisão pela Asaas (DT-01) e o CPF como identificador único (DT-14), os critérios de aceite foram reescritos sobre o que o MVP executa. Cada critério aponta o teste que o comprova.

## Doador (Guardião)

### US01. Aderir ao Clube

**Como** pessoa que já apoia o Instituto, **quero** me tornar Guardiã em menos de dois minutos, **para** doar todo mês sem precisar lembrar.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Escolho R$ 50, R$ 80, R$ 95 ou outro valor entre R$ 10 e R$ 5.000, e o dia do pagamento | T16, E02 |
| 2 | Informo nome, CPF, e-mail e WhatsApp; o CPF é validado pelos dígitos verificadores enquanto digito | T21, E01 |
| 3 | Sem marcar o consentimento LGPD, a adesão não é aceita, nem pela tela nem direto no banco | T02, E01 |
| 4 | Se meu CPF já tem assinatura ativa, vejo uma mensagem clara e nada é duplicado, mesmo com outro e-mail | T04, T22, E03 |
| 5 | O canal por onde cheguei (QR Code, Instagram, indicação) fica registrado | T16, E02 |
| 6 | Recebo a mensagem de boas-vindas no ato | T01, E07 |
| 7 | Meu CPF nunca fica gravado em texto aberto no banco do painel | T23, S10 |
| 8 | A página segue a identidade do Instituto, usa só imagens liberadas por ele e não promete dedução de Imposto de Renda | Revisão visual, E16 |

Em produção, depois do critério 6, a página encaminha para o checkout da Asaas, que cria a assinatura Pix (DT-04).

### US02. Ser reconhecido a cada doação

**Como** Guardiã, **quero** saber que a doação chegou e virou algo concreto, **para** continuar doando.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Quando o Pix é pago, recebo um agradecimento automático | T06, E09 |
| 2 | Se o aviso de pagamento chegar duas vezes, não recebo dois agradecimentos | T07 |
| 3 | Uma vez por mês recebo a notícia de impacto; repetir o envio não duplica | T13, E13 |

### US03. Não perder o vínculo quando o pagamento falha

**Como** Guardiã, **quero** ser lembrada quando esquecer o Pix, **para** não sair do Clube sem querer.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Se o Pix vence, recebo um lembrete e entro no alerta de churn do painel | T08, E10 |
| 2 | Se pago depois do lembrete, a cobrança vira recuperada e saio do alerta | T09, E11 |
| 3 | Depois de três vencimentos seguidos, a assinatura é encerrada e recebo a confirmação | T10, E12 |
| 4 | Posso cancelar a pedido; nenhuma cobrança nova é gerada | T11, E14 |
| 5 | Se eu voltar depois, com o mesmo CPF, uma nova assinatura é criada e meu histórico é preservado | T12 |

## Pessoa dedicada ao Clube (voluntário do painel)

### US04. Saber quem precisa de contato hoje

**Como** pessoa dedicada ao Clube, **quero** uma lista priorizada de quem está em risco, **para** usar bem as 24 horas mensais de retenção.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | A aba Alerta de churn lista quem tem cobrança em atraso, com prioridade e link de WhatsApp pronto | T08, E10 |
| 2 | Só entra no painel quem está na lista de voluntários; criar conta não dá acesso | S05, S06, E04 |

### US05. Operar o mês e prestar contas

**Como** pessoa dedicada ao Clube, **quero** acompanhar a arrecadação e exportar os números, **para** prestar contas aos doadores e à diretoria.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O resumo mostra ativos, receita do mês e cobertura do custeio de 2025, batendo com os lançamentos | T14, E05 |
| 2 | Baixo um CSV com 12 meses de métricas | E06 |
| 3 | Registro adesões presenciais de campanha | E15 |
| 4 | Vejo o resultado por canal de origem, para decidir onde investir as 56 horas de aquisição | Aba Canais (view `vw_origem_resultado`), revisão visual |

### US06. Localizar um Guardião pelo CPF

**Como** pessoa dedicada ao Clube, **quero** responder "este CPF já é Guardião?", **para** atender quem liga sem expor o CPF de ninguém.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Digito o CPF e o painel encontra o Guardião, se existir | T24, E07b |
| 2 | Visitante anônimo não consegue fazer essa consulta | S09 |
| 3 | Nem o voluntário consegue ler a impressão digital do CPF ou a chave | S10 |

### US07. Trazer a base atual sem perder ninguém

**Como** pessoa dedicada ao Clube, **quero** colocar no painel os Guardiões que já doam por Pix direto, **para** que toda a base receba a mesma comunicação e apareça nas métricas, e convidá-los aos poucos para a Asaas.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Cadastro com CPF e consentimento, sem trocar a forma de pagar | T25, E18 |
| 2 | O Pix direto conferido no extrato é registrado à mão, com agradecimento e rastro | T26, E18 |
| 3 | Pix direto não recebido gera lembrete e alerta de churn | T27 |
| 4 | Quem aceita migra para a Asaas mantendo valor, dia e histórico | T28, E18 |
| 5 | Só voluntário cadastrado faz essas operações | S11 |

## Fora do escopo do MVP (fase 2)

Doação de pessoa jurídica e comprovação fiscal corporativa; portal do doador para alterar valor ou dia; recibo anual automático.
