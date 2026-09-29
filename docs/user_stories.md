# User stories e critérios de aceite

Clube Guardiões do Começo | Instituto Ebenézer | atualizado em 28/09/2026

A numeração US01 a US06 é a mesma da semana 5 (protótipo navegável V7.0), para que a banca compare as duas entregas. Os critérios foram reescritos sobre o que o MVP executa, depois da decisão pela Asaas (DT-01), do CPF como identificador único (DT-14) e da evolução das telas da semana 5 (DT-16). US07 a US10 são histórias novas da pessoa dedicada ao Clube. Cada critério aponta o teste que o comprova.

## Doadora (persona Célia)

### US01. Cadastro e ativação de doação mensal via Pix

**Como** pessoa que já apoia o Instituto, **quero** me tornar Guardiã em poucos passos, **para** doar todo mês sem precisar lembrar.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O cadastro tem 3 etapas visíveis: Seus dados, Pagamento e Confirmação | E19 |
| 2 | Escolho R$ 50, R$ 80, R$ 95 ou outro valor entre R$ 10 e R$ 5.000, e o dia do pagamento | T16, E02 |
| 3 | Informo nome, CPF, e-mail e WhatsApp; o CPF é validado pelos dígitos verificadores e formatado enquanto digito | T21, E01 |
| 4 | Sem marcar o consentimento LGPD, com link para o Aviso de Privacidade, a adesão não é aceita, nem pela tela nem direto no banco | T02, E01, E19 |
| 5 | Se meu CPF já tem assinatura ativa, vejo uma mensagem clara e nada é duplicado, mesmo com outro e-mail | T04, T22, E03 |
| 6 | A tela de pagamento mostra o Pix com QR Code, código copia e cola e instruções em até 3 passos; se o Pix falhar, posso tentar de novo | E19 |
| 7 | A confirmação mostra o valor e a recorrência mensal | E19 |
| 8 | O canal por onde cheguei (QR Code, Instagram, convite) fica registrado | T16, T29, E02 |
| 9 | Meu CPF nunca fica gravado em texto aberto | T23, S10 |
| 10 | A página segue a identidade do Instituto, usa só imagens liberadas por ele e não promete dedução de Imposto de Renda | Revisão visual, E16 |

Em produção, o QR Code e o código copia e cola vêm da Asaas, que cria a assinatura Pix (DT-04).

### US02. Histórico e impacto das doações

**Como** Guardiã, **quero** saber que a doação chegou e virou algo concreto, **para** continuar doando.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Quando o Pix é pago, recebo um agradecimento automático, uma única vez | T06, T07, E09 |
| 2 | Uma vez por mês recebo a notícia de impacto com o que cada atividade sustentou, de forma agregada | T13, T30, E13, E20 |
| 3 | Meu histórico de cobranças e mensagens fica registrado | E07 |

Na semana 5, o histórico aparecia para a própria Guardiã na Minha Área. No MVP, ele está no banco e visível à equipe; a Minha Área é da fase 2 (US06).

### US03. Lembrete de vencimento e atraso

**Como** Guardiã, **quero** ser lembrada quando esquecer o Pix, **para** não sair do Clube sem querer.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Se o Pix vence, recebo um lembrete e entro no alerta de churn do painel | T08, E10 |
| 2 | Se pago depois do lembrete, a cobrança vira recuperada e saio do alerta | T09, E11 |
| 3 | Depois de três vencimentos seguidos, a assinatura é encerrada e recebo a confirmação | T10, E12 |

### US04. Indicação para o Clube

**Como** Guardiã, **quero** convidar alguém com um link meu, **para** trazer mais pessoas ao Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Depois da confirmação, posso copiar meu link pessoal ou compartilhar no WhatsApp | E19 |
| 2 | Posso pular esta etapa sem travar nada | E19 |
| 3 | Quem entra pelo meu link vê que foi convidado por mim, e a indicação fica registrada | T29, E19 |
| 4 | O link revela só meu primeiro nome, e nada mais | S12 |

### US05. Cancelamento de doação recorrente

**Como** Guardiã, **quero** cancelar quando precisar, sem burocracia, **para** confiar no Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O cancelamento exige confirmação, para evitar engano | E14 |
| 2 | Nenhuma cobrança nova é gerada e recebo a confirmação | T11, E14 |
| 3 | O motivo fica registrado | E14 |
| 4 | Se eu voltar depois, com o mesmo CPF, meu histórico é preservado | T12 |

No MVP, a equipe registra o cancelamento a pedido da Guardiã. O botão para a própria Guardiã fica na Minha Área, na fase 2.

### US06. Autenticação real da área restrita

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Painel da equipe: login real, e só e-mails cadastrados como voluntários acessam | S05, S06, E04 |
| 2 | Minha Área da Guardiã: login por código de verificação com expiração e bloqueio por tentativas | Fase 2 |

## Pessoa dedicada ao Clube (persona Ana)

### US07. Saber quem precisa de contato hoje

**Como** pessoa dedicada ao Clube, **quero** uma lista priorizada de quem está em risco, **para** usar bem as 24 horas mensais de retenção.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | A aba Alerta de churn lista quem tem cobrança em atraso, com prioridade e link de WhatsApp pronto | T08, E10 |
| 2 | Registro o contato feito, com anotação, e o alerta mostra o último contato | T31, E21 |

### US08. Operar o mês e prestar contas

**Como** pessoa dedicada ao Clube, **quero** acompanhar a arrecadação e registrar o que as doações sustentaram, **para** prestar contas aos Guardiões e à diretoria.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O resumo mostra ativos, receita do mês e cobertura do custeio de 2025, batendo com os lançamentos | T14, E05 |
| 2 | Registro o que cada atividade sustentou no mês; sem isso, a notícia de impacto não sai | T13, T30, E20 |
| 3 | Baixo um CSV com 12 meses de métricas | E06 |
| 4 | Registro adesões presenciais de campanha | E15 |
| 5 | Vejo o resultado por canal de origem, incluindo convites | Aba Canais, revisão visual |

### US09. Localizar um Guardião pelo CPF

**Como** pessoa dedicada ao Clube, **quero** responder "este CPF já é Guardião?", **para** atender quem liga sem expor o CPF de ninguém.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Digito o CPF e o painel encontra o Guardião, se existir | T24, E07b |
| 2 | Visitante anônimo não consegue fazer essa consulta | S09 |
| 3 | Nem o voluntário consegue ler a impressão digital do CPF ou a chave | S10 |

### US10. Trazer a base atual sem perder ninguém

**Como** pessoa dedicada ao Clube, **quero** colocar no painel os Guardiões que já doam por Pix direto, **para** que toda a base receba a mesma comunicação e apareça nas métricas, e convidá-los aos poucos para a Asaas.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Cadastro com CPF e consentimento, sem trocar a forma de pagar | T25, E18 |
| 2 | O Pix direto conferido no extrato é registrado à mão, com agradecimento e rastro | T26, E18 |
| 3 | Pix direto não recebido gera lembrete e alerta de churn | T27 |
| 4 | Quem aceita migra para a Asaas mantendo valor, dia e histórico | T28, E18 |
| 5 | Só voluntário cadastrado faz essas operações | S11 |

## Fora do escopo do MVP (fase 2)

Minha Área da Guardiã com login por código, histórico, linha do tempo de impacto e cancelamento pela própria Guardiã; recibo anual; doação de pessoa jurídica e comprovação fiscal corporativa. Detalhes em [rastreabilidade semana 5 → 10](rastreabilidade_semana5.md).
