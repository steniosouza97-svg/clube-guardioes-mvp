# Roteiro do vídeo demonstrativo

Clube Guardiões do Começo | duração alvo: 5 minutos e meio | gravação de tela com narração

Objetivo: mostrar o fluxo principal rodando de ponta a ponta sobre o banco real no Supabase, com dados sintéticos, e provar que foi testado. Cada cena cita o requisito do enunciado que ela atende.

## Antes de gravar

- Navegador em tela cheia, zoom 100%, idioma português.
- Painel já logado em uma aba; página de adesão aberta em outra, com `?origem=qr` no endereço.
- Mês de competência do painel no mês seguinte ao último com cobranças (o painel já abre assim).
- SQL Editor do Supabase aberto em uma terceira aba.
- Zerar a demonstração antes de gravar (README, seção "Zerar a demonstração").

## Cenas

| # | Tempo | Tela | O que fazer | O que dizer |
|---|---|---|---|---|
| 1 | 0:00 a 0:30 | Slide ou README | Mostrar o desenho do fluxo | "O problema do Instituto é previsibilidade. O Clube transforma doador pontual em doador mensal. Este MVP executa o fluxo inteiro: adesão, cobrança, pagamento ou atraso, régua de relacionamento e painel." |
| 2 | 0:30 a 1:30 | Página de adesão (as telas da semana 5) | "Quero participar"; etapa 1: R$ 80, e-mail `@example.com`, CPF fictício (`600.000.001-40`), consentimento; etapa 2: tela do Pix, "Já paguei"; etapa 3: confirmação; "convidar alguém" e mostrar o link pessoal | "É a mesma jornada do protótipo da semana 5, agora gravando no banco de verdade. O CPF é o identificador único, guardado só cifrado; o consentimento LGPD é obrigatório. No fim, a Guardiã ganha um link pessoal: quem entrar por ele fica registrado como convite dela." (Fluxo principal, modelo de dados) |
| 3 | 1:30 a 2:10 | Painel, Resumo | Passar pelos indicadores e gráficos | "Doze meses de operação simulada com dados sintéticos calibrados com o business case: ticket perto de R$ 80, churn perto de 2%. O indicador principal é a cobertura do custeio realizado em 2025." (Dados sintéticos) |
| 4 | 2:10 a 2:30 | Painel, Guardiões | Buscar a pessoa que acabou de aderir; abrir o histórico; consultar o CPF dela | "A adesão já está aqui, com o canal QR Code e a mensagem de boas-vindas registrada. O voluntário consegue saber se um CPF já é Guardião, mas nunca vê o número guardado." |
| 5 | 2:30 a 3:15 | Painel, Operação do mês | Gerar cobranças; simular a Asaas; mostrar os totais | "Cada mês a cobrança é gerada. Em produção, quem faz isso é a assinatura da Asaas; aqui, simulamos os avisos de Pix pago e Pix vencido, que passam pela mesma função que o webhook real vai chamar." (Fluxo principal, modelo de dados) |
| 6 | 3:15 a 3:55 | Painel, Alerta de churn | Mostrar a prioridade e o link de WhatsApp; voltar à operação e marcar "Pix pago" em um atraso | "Quem não pagou recebe o lembrete automático e entra no alerta. A pessoa dedicada ao Clube liga para os de prioridade alta. Quando o Pix chega, a cobrança vira recuperada e o Guardião sai do alerta." |
| 7 | 3:55 a 4:30 | Painel, Atividades e Operação do mês | Registrar o texto de uma atividade; enviar a notícia de impacto duas vezes | "A equipe registra o que cada atividade sustentou no mês, como no painel da Ana da semana 5. Esse texto chega a cada Guardião uma única vez." |
| 8 | 4:30 a 5:05 | SQL Editor do Supabase | Rodar `select * from qa.fn_rodar_testes();` e depois `qa.fn_testes_seguranca()` | "Trinta e um testes do fluxo e doze de acesso, rodando no próprio Supabase. Um visitante não enxerga dados de doadores, e criar uma conta não dá acesso ao painel." (Fase de testes, evidências) |
| 9 | 5:05 a 5:30 | README no repositório | Mostrar a estrutura e o manual de operação | "O repositório traz modelo de dados, decisões técnicas, instalação e o manual para a pessoa que vai operar o Clube depois de nós." (Handover) |

## Cuidados

- Nunca usar e-mail, CPF ou telefone reais. O banco de demonstração é verificado pelo teste T20.
- Não mostrar a chave secreta do Supabase nem qualquer chave da Asaas.
- Usar só imagens de crianças liberadas pelo Instituto (a foto da página já é liberada), em linha com o Manual de Boas Práticas para Redes Sociais.
