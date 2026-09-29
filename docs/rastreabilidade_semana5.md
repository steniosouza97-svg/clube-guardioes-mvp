# Da semana 5 à semana 10: rastreabilidade do protótipo ao MVP

Clube Guardiões do Começo | Instituto Ebenézer | atualizado em 29/09/2026

O MVP da semana 10 é a evolução do protótipo navegável V7.0 entregue na semana 5. O protótipo simulava as telas com dados de exemplo; o MVP executa o mesmo fluxo sobre um banco real, com dados sintéticos, regras de acesso e testes automatizados. Este documento mostra, tela a tela, o que foi implementado, o que evoluiu e o que ficou para a fase 2, com o motivo de cada decisão. Em 29/09 o escopo P1 e P2 da semana 5 foi fechado por inteiro: Login da Guardiã, Minha Área e Recibo, antes previstos para a fase 2, estão implementados (DT-17 e DT-18).

## Resumo

| | Telas do protótipo (semana 5) | No MVP | Fase 2 |
|---|---|---|---|
| Persona Célia (doadora) | 10 telas e 2 janelas | 10 telas e 2 janelas, várias evoluídas (cadastro, convite rastreável, Minha Área com pausa e estrelas) | Login por código de uso único no lugar de WhatsApp e CPF |
| Persona Ana (equipe) | 7 telas | 7, sendo Configurações pela tabela de parâmetros | Nenhuma |

## Persona Célia: jornada da doadora

| Tela da semana 5 | No MVP (semana 10) | Situação | Teste |
|---|---|---|---|
| Início (cartão verde, foto, "Quero participar", lema, Instagram) | Página de adesão, mesma identidade, foto e textos | Implementada | E01, E16 |
| Início: "Por que recorrência" e "Como funciona em 3 passos" | Mesmas seções, com as três atividades reais do Instituto | Implementada | E01 |
| Início: faixa "Você foi convidada por Maria" (simulada) | Faixa real: o link pessoal identifica quem convidou | Evoluída | E19, T29, S12 |
| Cadastro, etapa 1 de 3 (nome, WhatsApp, CPF, valor, consentimento) | Mesmo passo a passo, com escolha entre Guardião R$ 85/mês e doação única de qualquer valor, e-mail opcional, validação de CPF pelo dígito verificador, máscara de CPF e WhatsApp, e duplicidade barrada no banco | Evoluída | E01 a E03, E22, T01 a T04, T16, T21, T22, T32, T33 |
| Pagamento Pix, etapa 2 de 3 (QR Code, copia e cola, "Já paguei") | Mesma tela. O QR Code é ilustrativo; em produção vem da Asaas | Implementada | E19 |
| Erro no Pix ("Tentar novamente") | Mesma tela | Implementada | E19 |
| Confirmação, etapa 3 de 3 (resumo e recorrência) | Mesma tela, com o resumo gravado no banco | Implementada | E19 |
| Convite ("O ciclo continua", link pessoal, WhatsApp, pular) | Botão "Indique um novo Doador", para Guardião e doação única, que abre o WhatsApp com mensagem de impacto e link pessoal real e rastreável | Evoluída | E19, E22, T29, T33 |
| Aviso de Privacidade | Página própria, ligada ao consentimento e ao rodapé | Implementada | E19 |
| Janela "Cancelar cadastro" | "Cancelar e voltar ao início" no cadastro | Implementada | Revisão visual |
| Login da Guardiã (WhatsApp e CPF) | Tela "Entrar" pelo link "Minha Área" no topo (`fn_area`), com bloqueio após 5 tentativas erradas em 15 minutos e mensagem genérica; botão "Entrar com o Guardião de demonstração". Antes de produção, troca por código de uso único (DT-18) | Implementada | E23, T35, S13 |
| Minha Área (status, próxima cobrança, linha do tempo de impacto, histórico, cancelar e reativar) | Mesma tela, com medalha de nível e estrelas, status, alerta de atraso, linha do tempo de impacto (12 meses), histórico (24 meses), pausar de 1 a 3 meses, cancelar com motivo (o diálogo oferece pausar antes), reativar por R$ 85 e indicar (`fn_area_acao`) | Evoluída | E23, T34, T36, T37 |
| Recibo | Recibo anual com as doações pagas, mensais e únicas do mesmo CPF, só para o próprio Guardião, "sem dedução de Imposto de Renda para pessoa física" (`fn_area_recibo`) | Implementada | E23, T38 |

## Persona Ana: painel da equipe

| Tela da semana 5 | No MVP (semana 10) | Situação | Teste |
|---|---|---|---|
| Login da equipe | Login real no Supabase, só para e-mails cadastrados como voluntários | Evoluída | E04, S05, S06 |
| Painel (indicadores e "Precisa de atenção") | Aba Resumo, com 9 indicadores (inclui Guardiões no Clube, Pausados e Doações únicas no mês), gráficos e cobertura do custeio | Implementada | E05, E24, T14 |
| Guardiões (lista com filtros) | Aba Guardiões, com busca, filtros por situação (inclui "pausado") e canal, coluna Nível com estrelas, botões Pausar 1 mês e Retomar, e consulta por CPF; aba nova Doações únicas | Evoluída | E07, E07b, E24, T34, S13 |
| Detalhe do Guardião (histórico, "Marcar como regularizado") | Detalhe com cobranças e régua; regularização em Operação do mês | Implementada | E07, E11 |
| Atividades e prestação de contas | Aba Atividades: o texto do mês por atividade vai na notícia de impacto | Implementada | E20, T13, T30 |
| Lembretes e cobranças em atraso ("Registrar contato feito") | Aba Alerta de churn, com prioridade, link de WhatsApp e registro do contato | Implementada | E10, E21, T31 |
| Configurações | Parâmetros do Clube na tabela `parametro` (inclui valor do Guardião, pausa máxima e meses por estrela), alterados pelo Instituto sem mexer em código | Implementada fora da tela | |

## O que o MVP tem a mais que o protótipo

| Recurso | Por quê | Teste |
|---|---|---|
| Banco de dados real com regras de negócio | O enunciado da semana 10 exige modelo de dados e operação estável | T01 a T38 |
| Dados sintéticos de 12 meses | Exigência do enunciado; calibrados com o business case | T19, T20 |
| Operação do mês (gerar cobranças, simular a Asaas, enviar a notícia) | Mostra o ciclo mensal funcionando de ponta a ponta | E08, E09, E13 |
| Base atual em Pix direto e migração para a Asaas | Os 35 Guardiões de hoje não passam pela Asaas (DT-15) | T25 a T28, E18 |
| Canais de aquisição | Mede onde as 56 horas mensais de captação rendem mais | E15 |
| CPF cifrado | O CPF é o identificador único da semana 5, guardado sem expor o número (DT-14) | T23, S10 |
| Doação única de qualquer valor | Porta de entrada para quem não pode doar todo mês, sem distorcer as métricas de recorrência (DT-17) | T33, S13, E22 |
| Pausa em vez de cancelamento | Alternativa para quem passa por um aperto; volta sozinha em 1 a 3 meses (DT-17) | T34, T36, E23, E24 |
| Estrelas e níveis (Bronze, Prata, Ouro) | Reconhece a constância; uma estrela a cada 3 meses pagos (DT-17) | T37, E23, E24 |

## Diferenças deliberadas, e por quê

1. **Minha Área com o login do protótipo, e não com código.** Em 28/09 a Minha Área, o login da Guardiã e o recibo tinham ficado para a fase 2, porque a semana 5 registrou (US06) que o login real exige código de verificação, expiração e bloqueio por tentativas. Em 29/09 decidiu-se entregá-los na banca, com a entrada por WhatsApp e CPF do protótipo, aceitável com dados sintéticos e protegida por bloqueio após 5 tentativas erradas, mensagem genérica e nenhum dado sensível devolvido. Antes de operar com doadores reais, a entrada passa a ser por código de uso único no WhatsApp ou link mágico por e-mail (DT-18).
2. **Guardião de R$ 85 por mês e doação única de qualquer valor.** O protótipo oferecia R$ 30, R$ 60, R$ 120 ou outro valor mensal. Em 29/09 o Guardião passou a ter um valor único, R$ 85 por mês (parâmetro `valor_guardiao`), e os valores do protótipo voltaram como sugestão da doação única, de R$ 10 a R$ 50.000. Os Guardiões que já doam mantêm o valor atual (DT-17).
3. **E-mail opcional.** A V4 do protótipo retirou o e-mail para reduzir atrito; a versão de 28/09 do MVP o exigia. Em 29/09 ficou opcional, para Guardião e doação única, validado quando informado. WhatsApp e CPF continuam obrigatórios. Sem e-mail, o recibo anual continua disponível na Minha Área.
4. **Asaas, e não Doare.** O protótipo citava a Doare para a semana 10. A análise financeira levou à Asaas, já contratada (DT-01).
5. **Grupo de WhatsApp dos Guardiões.** O protótipo prometia inclusão automática no grupo. O MVP usa o WhatsApp para mensagens individuais (Pix, agradecimento, lembrete, notícia); o grupo continua sendo uma decisão do Instituto.
6. **Doação vinculada a uma atividade.** O protótipo mostrava cada doação vinculada a uma atividade específica. O MVP presta contas por atividade de forma agregada para todos os Guardiões, que é o que a equipe consegue produzir todo mês; o vínculo individual é da fase 2. A Minha Área mostra a linha do tempo de impacto dos últimos 12 meses.

## Fase 2 (depois da semana 10)

| Item | Depende de |
|---|---|
| Login da Minha Área por código de uso único no WhatsApp ou link mágico por e-mail (US06 da semana 5), no lugar de WhatsApp e CPF | Supabase Auth ou serviço de envio pelo WhatsApp; política de acesso por Guardião (DT-18) |
| Modelo oficial do recibo anual | Definição do Instituto sobre o modelo de recibo; o recibo atual já sai na Minha Área |
| Checkout e webhook reais da Asaas, incluindo doação única como cobrança avulsa e pausa espelhada na assinatura | Chave de API da Asaas e Edge Function (DT-04, DT-17) |
| Vínculo individual da doação a uma atividade | Definição do Instituto sobre como vincular |
