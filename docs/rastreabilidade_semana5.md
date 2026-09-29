# Da semana 5 à semana 10: rastreabilidade do protótipo ao MVP

Clube Guardiões do Começo | Instituto Ebenézer | atualizado em 28/09/2026

O MVP da semana 10 é a evolução do protótipo navegável V7.0 entregue na semana 5. O protótipo simulava as telas com dados de exemplo; o MVP executa o mesmo fluxo sobre um banco real, com dados sintéticos, regras de acesso e testes automatizados. Este documento mostra, tela a tela, o que foi implementado, o que evoluiu e o que ficou para a fase 2, com o motivo de cada decisão.

## Resumo

| | Telas do protótipo (semana 5) | No MVP | Fase 2 |
|---|---|---|---|
| Persona Célia (doadora) | 10 telas e 2 janelas | 7 telas e 1 janela, duas delas evoluídas (cadastro e convite rastreável) | Login, Minha Área e Recibo |
| Persona Ana (equipe) | 7 telas | 7, sendo Configurações pela tabela de parâmetros | Nenhuma |

## Persona Célia: jornada da doadora

| Tela da semana 5 | No MVP (semana 10) | Situação | Teste |
|---|---|---|---|
| Início (cartão verde, foto, "Quero participar", lema, Instagram) | Página de adesão, mesma identidade, foto e textos | Implementada | E01, E16 |
| Início: "Por que recorrência" e "Como funciona em 3 passos" | Mesmas seções, com as três atividades reais do Instituto | Implementada | E01 |
| Início: faixa "Você foi convidada por Maria" (simulada) | Faixa real: o link pessoal identifica quem convidou | Evoluída | E19, T29, S12 |
| Cadastro, etapa 1 de 3 (nome, WhatsApp, CPF, valor, consentimento) | Mesmo passo a passo, com validação de CPF pelo dígito verificador, máscara de CPF e WhatsApp, e duplicidade barrada no banco | Evoluída | E01 a E03, T01 a T04, T21, T22 |
| Pagamento Pix, etapa 2 de 3 (QR Code, copia e cola, "Já paguei") | Mesma tela. O QR Code é ilustrativo; em produção vem da Asaas | Implementada | E19 |
| Erro no Pix ("Tentar novamente") | Mesma tela | Implementada | E19 |
| Confirmação, etapa 3 de 3 (resumo e recorrência) | Mesma tela, com o resumo gravado no banco | Implementada | E19 |
| Convite ("O ciclo continua", link pessoal, WhatsApp, pular) | Mesma tela, com link pessoal real e rastreável | Implementada | E19, T29 |
| Aviso de Privacidade | Página própria, ligada ao consentimento e ao rodapé | Implementada | E19 |
| Janela "Cancelar cadastro" | "Cancelar e voltar ao início" no cadastro | Implementada | Revisão visual |
| Login da Guardiã (WhatsApp e CPF) | Fase 2 | Fase 2 | |
| Minha Área (status, próxima cobrança, linha do tempo de impacto, histórico, cancelar e reativar) | Fase 2. Os dados já existem no banco e a equipe os vê no detalhe do Guardião | Fase 2 | T13, T30 |
| Recibo | Fase 2 | Fase 2 | |

## Persona Ana: painel da equipe

| Tela da semana 5 | No MVP (semana 10) | Situação | Teste |
|---|---|---|---|
| Login da equipe | Login real no Supabase, só para e-mails cadastrados como voluntários | Evoluída | E04, S05, S06 |
| Painel (indicadores e "Precisa de atenção") | Aba Resumo, com indicadores do mês, gráficos e cobertura do custeio | Implementada | E05, T14 |
| Guardiões (lista com filtros) | Aba Guardiões, com busca, filtros por situação e canal, e consulta por CPF | Implementada | E07, E07b |
| Detalhe do Guardião (histórico, "Marcar como regularizado") | Detalhe com cobranças e régua; regularização em Operação do mês | Implementada | E07, E11 |
| Atividades e prestação de contas | Aba Atividades: o texto do mês por atividade vai na notícia de impacto | Implementada | E20, T13, T30 |
| Lembretes e cobranças em atraso ("Registrar contato feito") | Aba Alerta de churn, com prioridade, link de WhatsApp e registro do contato | Implementada | E10, E21, T31 |
| Configurações | Parâmetros do Clube na tabela `parametro`, alterados pelo Instituto sem mexer em código | Implementada fora da tela | |

## O que o MVP tem a mais que o protótipo

| Recurso | Por quê | Teste |
|---|---|---|
| Banco de dados real com regras de negócio | O enunciado da semana 10 exige modelo de dados e operação estável | T01 a T31 |
| Dados sintéticos de 12 meses | Exigência do enunciado; calibrados com o business case | T19, T20 |
| Operação do mês (gerar cobranças, simular a Asaas, enviar a notícia) | Mostra o ciclo mensal funcionando de ponta a ponta | E08, E09, E13 |
| Base atual em Pix direto e migração para a Asaas | Os 35 Guardiões de hoje não passam pela Asaas (DT-15) | T25 a T28, E18 |
| Canais de aquisição | Mede onde as 56 horas mensais de captação rendem mais | E15 |
| CPF cifrado | O CPF é o identificador único da semana 5, guardado sem expor o número (DT-14) | T23, S10 |

## Diferenças deliberadas, e por quê

1. **Minha Área, login da Guardiã e recibo ficaram para a fase 2.** O protótipo fazia o login conferindo WhatsApp e CPF digitados, sem verificação. A própria semana 5 registrou (US06) que o login real exige código de verificação, expiração e bloqueio por tentativas. Publicar uma área com dados pessoais de doadores sem essa autenticação seria um risco de LGPD. Os dados que a Minha Área mostraria (histórico, linha do tempo de impacto) já estão no banco; na fase 2 é só construir a tela sobre eles com login por código.
2. **Valores de R$ 50, R$ 80 e R$ 95, em vez de R$ 30, R$ 60 e R$ 120.** Alinhados ao business case: R$ 80 é o ticket médio real dos 35 Guardiões e R$ 95 custeia uma criança por um mês. Com custo de R$ 3,09 por Guardião, doações muito baixas perdem eficiência (slide 12). O valor livre continua aceito a partir de R$ 10.
3. **E-mail no cadastro.** A V4 do protótipo retirou o e-mail para reduzir atrito. O MVP o mantém porque a Asaas envia a cobrança e o comprovante por e-mail, e o recibo anual depende dele.
4. **Asaas, e não Doare.** O protótipo citava a Doare para a semana 10. A análise financeira levou à Asaas, já contratada (DT-01).
5. **Grupo de WhatsApp dos Guardiões.** O protótipo prometia inclusão automática no grupo. O MVP usa o WhatsApp para mensagens individuais (Pix, agradecimento, lembrete, notícia); o grupo continua sendo uma decisão do Instituto.
6. **Doação vinculada a uma atividade.** O protótipo mostrava cada doação vinculada a uma atividade específica. O MVP presta contas por atividade de forma agregada para todos os Guardiões, que é o que a equipe consegue produzir todo mês; o vínculo individual é da fase 2, junto com a Minha Área.

## Fase 2 (depois da semana 10)

| Item | Depende de |
|---|---|
| Minha Área da Guardiã, com login por código (US06 da semana 5) | Supabase Auth com código por e-mail ou WhatsApp; política de acesso por Guardião |
| Recibo anual | Minha Área e definição do Instituto sobre o modelo de recibo |
| Checkout e webhook reais da Asaas | Chave de API da Asaas e Edge Function (DT-04) |
| Vínculo individual da doação a uma atividade | Minha Área |
