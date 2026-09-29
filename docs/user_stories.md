# User stories e critérios de aceite

Clube Guardiões do Futuro | Instituto Ebenézer | atualizado em 29/09/2026

A numeração US01 a US06 é a mesma da semana 5 (protótipo navegável V7.0), para que a banca compare as duas entregas. Os critérios foram reescritos sobre o que o MVP executa, depois da decisão pela Asaas (DT-01), do CPF como identificador único (DT-14), da evolução das telas da semana 5 (DT-16) e das decisões de 29/09 (DT-17 e DT-18): Guardião doa R$ 85 por mês, doação única de qualquer valor, e-mail opcional, pausa, Minha Área, recibo anual, estrelas e "Indique um novo Doador". US07 a US10 são histórias novas da pessoa dedicada ao Clube; US11 a US15 vêm das decisões de 29/09. Cada critério aponta o teste que o comprova.

## Doadora (persona Célia)

### US01. Cadastro e ativação de doação mensal via Pix

**Como** pessoa que já apoia o Instituto, **quero** me tornar Guardiã em poucos passos, **para** doar todo mês sem precisar lembrar.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O cadastro tem 3 etapas visíveis: Seus dados, Pagamento e Confirmação | E19 |
| 2 | Na página, escolho entre "Guardião R$ 85/mês (recomendado)" e "Doação única, qualquer valor"; como Guardiã, doo R$ 85 por mês e escolho o dia do pagamento; outro valor mensal é recusado e a página oferece a doação única (US11) | T16, E02 |
| 3 | Informo nome, CPF e WhatsApp; o e-mail é opcional e, se informado, precisa ser válido; o CPF é validado pelos dígitos verificadores e formatado enquanto digito | T21, T32, E01, E19 |
| 4 | Sem marcar o consentimento LGPD, com link para o Aviso de Privacidade, a adesão não é aceita, nem pela tela nem direto no banco | T02, E01, E19 |
| 5 | Se meu CPF já tem assinatura ativa, vejo uma mensagem clara e nada é duplicado, mesmo com outro e-mail | T04, T22, E03 |
| 6 | A tela de pagamento mostra o Pix com QR Code, código copia e cola e instruções em até 3 passos; se o Pix falhar, posso tentar de novo | E19 |
| 7 | A confirmação mostra o valor e a recorrência mensal | E19 |
| 8 | O canal por onde cheguei (QR Code, Instagram, convite) fica registrado | T16, T29, E02 |
| 9 | Meu CPF nunca fica gravado em texto aberto | T23, S10 |
| 10 | A página segue a identidade do Instituto, usa só imagens liberadas por ele e não promete dedução de Imposto de Renda | Revisão visual, E16 |

Os Guardiões que já doam (os 35 da base em Pix direto e os da base sintética) mantêm o valor atual; os R$ 85 valem para novas adesões e reativações (DT-17). Em produção, o QR Code e o código copia e cola vêm da Asaas, que cria a assinatura Pix (DT-04).

### US02. Histórico e impacto das doações

**Como** Guardiã, **quero** saber que a doação chegou e virou algo concreto, **para** continuar doando.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Quando o Pix é pago, recebo um agradecimento automático, uma única vez | T06, T07, E09 |
| 2 | Uma vez por mês recebo a notícia de impacto com o que cada atividade sustentou, de forma agregada | T13, T30, E13, E20 |
| 3 | Meu histórico de cobranças e mensagens fica registrado | E07 |
| 4 | Vejo meu histórico (24 meses) e a linha do tempo de impacto (12 meses) na Minha Área | T35, E23 |

Como no protótipo da semana 5, o histórico e o impacto aparecem para a própria Guardiã na Minha Área (US13), e a equipe vê os mesmos dados no detalhe do Guardião.

### US03. Lembrete de vencimento e atraso

**Como** Guardiã, **quero** ser lembrada quando esquecer o Pix, **para** não sair do Clube sem querer.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Se o Pix vence, recebo um lembrete e entro no alerta de churn do painel | T08, E10 |
| 2 | Se pago depois do lembrete, a cobrança vira recuperada e saio do alerta | T09, E11 |
| 3 | Depois de três vencimentos seguidos, a assinatura é encerrada e recebo a confirmação | T10, E12 |
| 4 | Na Minha Área, vejo um alerta quando tenho Pix em atraso | E23 |

### US04. Indicação para o Clube

**Como** Guardiã, **quero** convidar alguém com um link meu, **para** trazer mais pessoas ao Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Depois da confirmação, vejo o botão "Indique um novo Doador" e compartilho meu link pessoal pelo WhatsApp | E19 |
| 2 | Posso pular esta etapa sem travar nada | E19 |
| 3 | Quem entra pelo meu link vê que foi convidado por mim, e a indicação fica registrada | T29, E19 |
| 4 | O link revela só meu primeiro nome, e nada mais | S12 |

A mensagem de impacto e a indicação a partir da doação única estão na US15.

### US05. Cancelamento de doação recorrente

**Como** Guardiã, **quero** cancelar quando precisar, sem burocracia, **para** confiar no Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | O cancelamento exige confirmação, para evitar engano, e antes me oferece pausar (US12) | E14, E23 |
| 2 | Nenhuma cobrança nova é gerada e recebo a confirmação | T11, T36, E14 |
| 3 | O motivo fica registrado (até 200 caracteres, quando cancelo pela Minha Área) | T36, E14, E23 |
| 4 | Se eu voltar depois, com o mesmo CPF, meu histórico é preservado; pela Minha Área reativo como Guardiã de R$ 85 | T12, T36, E23 |

A própria Guardiã cancela e reativa pela Minha Área (US13); a equipe continua podendo registrar o cancelamento a pedido pelo painel.

### US06. Autenticação real da área restrita

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Painel da equipe: login real, e só e-mails cadastrados como voluntários acessam | S05, S06, E04 |
| 2 | Minha Área da Guardiã: entrada por WhatsApp e CPF, como no protótipo, com bloqueio após 5 tentativas erradas em 15 minutos e mensagem genérica de erro | T35, S13, E23 |

O login por WhatsApp e CPF serve para a demonstração com dados sintéticos. Antes de operar com doadores reais, troca-se por código de uso único enviado ao WhatsApp, com expiração, ou por link mágico por e-mail (DT-18).

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
| 1 | O resumo mostra Guardiões no Clube (ativos e pausados), pausados, doações únicas do mês, receita do mês e cobertura do custeio de 2025, batendo com os lançamentos | T14, E05, E24 |
| 2 | Registro o que cada atividade sustentou no mês; sem isso, a notícia de impacto não sai | T13, T30, E20 |
| 3 | Baixo um CSV com 12 meses de métricas | E06 |
| 4 | Registro adesões presenciais de campanha | E15 |
| 5 | Vejo o resultado por canal de origem, incluindo convites | Aba Canais, revisão visual |
| 6 | Vejo as doações únicas numa aba própria, sem o CPF, com quem convidou e quantas indicações cada uma gerou | S13, E24 |
| 7 | Pauso por 1 mês ou retomo a doação de um Guardião a pedido dele | T34, E24 |

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
| 1 | Cadastro com CPF e consentimento, sem trocar a forma de pagar nem o valor que já doam | T25, E18 |
| 2 | O Pix direto conferido no extrato é registrado à mão, com agradecimento e rastro | T26, E18 |
| 3 | Pix direto não recebido gera lembrete e alerta de churn | T27 |
| 4 | Quem aceita migra para a Asaas mantendo valor, dia e histórico | T28, E18 |
| 5 | Só voluntário cadastrado faz essas operações | S11 |

## Decisões de 29/09 (DT-17 e DT-18)

### US11. Doação única de qualquer valor

**Como** pessoa que quer ajudar mas não pode assumir um valor mensal, **quero** fazer uma doação única do valor que eu escolher, **para** apoiar o Instituto sem compromisso recorrente.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Escolho R$ 30, R$ 60, R$ 120 (valores do protótipo da semana 5) ou outro valor, de R$ 10 a R$ 50.000 | T33, E22 |
| 2 | Informo nome, CPF e WhatsApp; o e-mail é opcional e, se informado, precisa ser válido; sem consentimento LGPD a doação não é aceita | T32, T33, E22 |
| 3 | Pago por Pix, sem recorrência; a doação é confirmada uma única vez, mesmo que o aviso se repita | T33, E22 |
| 4 | Meu CPF fica só cifrado; o visitante anônimo faz a doação mas não lê nenhuma doação registrada | S13 |
| 5 | Ao final, vejo o botão "Indique um novo Doador" (US15) | T33, E22 |

Na demonstração, "Já paguei" confirma a doação (`fn_confirmar_doacao_demo`, só com `modo_demonstracao = 1`). Em produção, quem confirma é o webhook da Asaas (`fn_processar_doacao_unica`), fora do alcance do visitante (S13).

### US12. Pausar em vez de cancelar

**Como** Guardiã que passa por um aperto, **quero** pausar a doação por alguns meses, **para** não precisar sair do Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Pauso por 1, 2 ou 3 meses; mais do que isso não é aceito | T34, T36, E23 |
| 2 | A cobrança do mês em aberto é cancelada e nenhuma cobrança é gerada durante a pausa | T34 |
| 3 | A doação volta sozinha no mês escolhido, e recebo as mensagens de pausa e de retomada | T34 |
| 4 | Posso retomar antes do prazo pela Minha Área | T36, E23 |
| 5 | Ao pedir o cancelamento, a Minha Área me oferece pausar antes | E23 |
| 6 | A equipe vê quem está pausado e a data de volta, e pausa ou retoma a pedido; o anônimo não pausa pelo painel | T34, S13, E24 |

### US13. Minha Área da Guardiã

**Como** Guardiã, **quero** uma área minha, **para** acompanhar minha doação e resolver tudo sem depender da equipe.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Entro pelo link "Minha Área", no topo da página, com WhatsApp e CPF; com dados errados, a mensagem é genérica e não diz qual dos dois não confere | T35, S13, E23 |
| 2 | Depois de 5 tentativas erradas em 15 minutos, o acesso fica bloqueado | T35 |
| 3 | A área não devolve e-mail, telefone nem CPF: só primeiro nome, status, valores e histórico | T35 |
| 4 | Vejo status, alerta de atraso, linha do tempo de impacto (12 meses) e histórico (24 meses) | E23 |
| 5 | Pauso, retomo, cancelo com motivo e reativo por R$ 85 | T36, E23 |
| 6 | Emito o recibo anual com as doações pagas (mensais e únicas do mesmo CPF), sem promessa de dedução de Imposto de Renda | T38, E23 |
| 7 | O recibo só sai para o próprio Guardião: com o CPF de outra pessoa, nada é emitido | T38 |

Para a demonstração, o botão "Entrar com o Guardião de demonstração" usa o Guardião sintético Carlos Soares. Riscos e passo antes da produção na DT-18.

### US14. Estrelas e níveis de Guardião

**Como** Guardiã, **quero** ver minha constância reconhecida, **para** ter orgulho de continuar no Clube.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Ganho uma estrela a cada 3 meses pagos | T37, E23 |
| 2 | Com 3 estrelas sou Guardião Bronze, com 4 Prata, com 5 ou mais Ouro | T37 |
| 3 | Vejo minha medalha de nível com as estrelas na Minha Área | E23 |
| 4 | A equipe vê o nível e as estrelas de cada Guardião no painel | E24 |
| 5 | Ao entrar na Minha Área, sou recebida pela minha conquista ("Carlos, você já é um Guardião Prata!"), com meses de doação, total doado e indicações | E23 |
| 6 | Vejo quantos meses faltam para o próximo nível (por exemplo, "Faltam 3 meses para você se tornar Guardião do Futuro Ouro"), a trilha das 5 estrelas e o mês previsto para chegar lá com o Pix em dia | E23 |

As estrelas são calculadas a partir das cobranças pagas, sem nenhum dado novo guardado; o número de meses por estrela está na tabela `parametro` (DT-17).

### US15. "Indique um novo Doador" pelo WhatsApp

**Como** doador (Guardião ou de doação única), **quero** convidar alguém pelo WhatsApp com uma mensagem pronta, **para** multiplicar o apoio ao Instituto.

| # | Critério de aceite | Teste |
|---|---|---|
| 1 | Depois de doar, como Guardião ou em doação única, vejo o botão "Indique um novo Doador" | E19, E22 |
| 2 | O botão abre o WhatsApp com uma mensagem de impacto (120 crianças no Jardim Ângela, R$ 85 por mês ou doação única de qualquer valor) e o meu link pessoal | E19, E22 |
| 3 | Na Minha Área também posso indicar | E23 |
| 4 | Quem entra pelo meu link, como Guardião ou em doação única, fica com o convite registrado, e o painel conta as indicações | T29, T33, E19, E24 |
| 5 | O link de uma doação única só vale depois de paga | T33 |
| 6 | O link revela só meu primeiro nome | S12 |

## Fora do escopo do MVP (fase 2)

Login da Minha Área por código de uso único no WhatsApp ou link mágico por e-mail (DT-18); checkout e webhook reais da Asaas; doação de pessoa jurídica e comprovação fiscal corporativa; vínculo individual da doação a uma atividade. Detalhes em [rastreabilidade semana 5 → 10](rastreabilidade_semana5.md).
