# Roteiro do vídeo demonstrativo

Clube Guardiões do Futuro | duração alvo: 7 minutos | gravação de tela com narração

Objetivo: mostrar o fluxo principal rodando de ponta a ponta sobre o banco real no Supabase, com dados sintéticos, e provar que foi testado. Cada cena cita o requisito do enunciado que ela atende.

## Antes de gravar

- Navegador em tela cheia, zoom 100%, idioma português.
- Painel já logado em uma aba; página de adesão aberta em outra, com `?origem=qr` no endereço.
- WhatsApp Web aberto (ou celular espelhado) só para mostrar a mensagem de indicação montada, sem enviar a ninguém.
- Mês de competência do painel no mês seguinte ao último com cobranças (o painel já abre assim).
- SQL Editor do Supabase aberto em uma terceira aba.
- Zerar a demonstração antes de gravar ([operação](operacao.md), seção "Zerar a demonstração").

## Cenas

| # | Tempo | Tela | O que fazer | O que dizer |
|---|---|---|---|---|
| 1 | 0:00 a 0:25 | Slide 4 do deck (a jornada) ou README | Mostrar o desenho do fluxo | "O problema do Instituto é previsibilidade. O Clube transforma doador pontual em doador mensal. Este MVP executa o fluxo inteiro: adesão, cobrança, pagamento ou atraso, régua de relacionamento e painel." |
| 2 | 0:25 a 0:45 | Página de adesão, início | Mostrar os dois caminhos: "Guardião R$ 85/mês (recomendado)" e "Doação única, qualquer valor" | "Quem chega escolhe: virar Guardião com R$ 85 por mês, ou fazer uma doação única de qualquer valor. O recorrente é o recomendado, mas ninguém sai sem poder ajudar." (Fluxo principal) |
| 3 | 0:45 a 1:35 | Página de adesão (as telas da semana 5) | Guardião: etapa 1 com CPF fictício (`600.000.001-40`), WhatsApp fictício, sem e-mail, consentimento; etapa 2: tela do Pix, "Já paguei"; etapa 3: confirmação | "É a mesma jornada do protótipo da semana 5, agora gravando no banco de verdade. O e-mail é opcional; WhatsApp e CPF são obrigatórios, e o CPF fica guardado só cifrado. O consentimento LGPD é obrigatório." (Fluxo principal, modelo de dados) |
| 4 | 1:35 a 1:55 | Confirmação e WhatsApp | Clicar em "Indique um novo Doador"; mostrar a mensagem de impacto com o link pessoal, sem enviar | "Depois de doar, todo doador pode indicar alguém pelo WhatsApp. A mensagem já conta o impacto e leva um link pessoal: quem doar por ele fica registrado como indicação, e quem abre o link vê só o primeiro nome de quem convidou." |
| 5 | 1:55 a 2:15 | Página de adesão | Voltar ao início; doação única de R$ 60, sem e-mail; "Já paguei"; confirmação | "A doação única segue o mesmo caminho, com os mesmos cuidados de dados, e também termina com o convite para indicar." |
| 6 | 2:15 a 2:55 | Minha Área | Clicar em **Minha Área** e em **Entrar como Guardião de demonstração**; mostrar "Carlos, você já é um Guardião Prata!", 4 estrelas e "a apenas 1 estrela de ser Guardião do Futuro Ouro", status, linha do tempo de impacto e histórico | "O Guardião entra com WhatsApp e CPF. Vê o nível, as estrelas (a primeira na primeira doação e mais uma a cada três meses; Ouro em 12 meses), o que a doação sustentou mês a mês e o histórico. A tela nunca mostra CPF, telefone ou e-mail." |
| 7 | 2:55 a 3:10 | Minha Área, recibo | Clicar em "Emitir recibo" | "O recibo anual sai na hora, só para o próprio Guardião, e diz com clareza que não há dedução de Imposto de Renda para pessoa física." (Prestação de contas) |
| 8 | 3:10 a 3:35 | Minha Área, cancelar | Clicar em cancelar; no diálogo, clicar em "Prefiro pausar" (1 mês); mostrar a data de volta; clicar em retomar | "Antes de perder um Guardião, o Clube oferece a pausa: de um a três meses, sem cobrança, e a doação volta sozinha. É retenção desenhada na própria tela." |
| 9 | 3:35 a 4:10 | Painel, Resumo | Passar pelos 9 indicadores e gráficos: Guardiões no Clube (ativos e pausados), pausados, doações únicas no mês | "Doze meses de operação simulada com dados sintéticos calibrados com o business case: 305 Guardiões, 271 ativos, 4 pausados e 48 doações únicas. O indicador principal é a cobertura do custeio realizado em 2025." (Dados sintéticos) |
| 10 | 4:10 a 4:40 | Painel, Guardiões e Doações únicas | Buscar a pessoa que acabou de aderir; abrir o histórico; consultar o CPF; mostrar a coluna Nível, o filtro "pausado" com a data de volta e o botão **Pausar 1 mês**; abrir a aba **Doações únicas** | "A adesão já está aqui, com o canal QR Code e a boas-vindas registrada. O voluntário vê nível, pausados e doações únicas, pausa a pedido do Guardião e sabe se um CPF já é Guardião sem nunca ver o número." |
| 11 | 4:40 a 5:15 | Painel, Operação do mês | Gerar cobranças; simular a Asaas; mostrar os totais | "Cada mês a cobrança é gerada, e quem está pausado não é cobrado. Em produção, quem faz isso é a assinatura da Asaas; aqui, simulamos os avisos de Pix pago e Pix vencido, que passam pela mesma função que o webhook real vai chamar." (Fluxo principal, modelo de dados) |
| 12 | 5:15 a 5:45 | Painel, Alerta de churn | Mostrar a prioridade e o link de WhatsApp; voltar à operação e marcar "Pix pago" em um atraso | "Quem não pagou recebe o lembrete automático e entra no alerta. A pessoa dedicada ao Clube liga para os de prioridade alta. Quando o Pix chega, a cobrança vira recuperada e o Guardião sai do alerta." |
| 13 | 5:45 a 6:10 | Painel, Atividades e Operação do mês | Registrar o texto de uma atividade; enviar a notícia de impacto duas vezes | "A equipe registra o que cada atividade sustentou no mês, como no painel da Ana da semana 5. Esse texto chega a cada Guardião uma única vez e alimenta a linha do tempo da Minha Área." |
| 14 | 6:10 a 6:40 | SQL Editor do Supabase | Rodar `select * from qa.fn_rodar_testes();` e depois `qa.fn_testes_seguranca()` | "Trinta e nove testes do fluxo e treze de acesso, rodando no próprio Supabase, mais 25 passos de interface no navegador e as telas conferidas no celular, no tablet e no computador. Um visitante não enxerga dados de doadores, só entra na Minha Área com os dados certos, e criar uma conta não dá acesso ao painel." (Fase de testes, evidências) |
| 15 | 6:40 a 7:00 | README no repositório | Mostrar as telas, a arquitetura e o manual de operação | "O repositório traz modelo de dados, decisões técnicas, instalação e o manual para a pessoa que vai operar o Clube depois de nós." (Handover) |

## Cuidados

- Nunca usar e-mail, CPF ou telefone reais. O banco de demonstração é verificado pelo teste T20. O Guardião de demonstração (Carlos Barbosa) é sintético.
- Na cena 4, não enviar a mensagem de indicação a nenhum contato real.
- Na cena 8, retomar a doação do Guardião de demonstração ao final, para que o painel continue com 4 pausados. Se algo sair do roteiro, zerar a demonstração e regravar.
- Não mostrar a chave secreta do Supabase nem qualquer chave da Asaas.
- Usar só imagens de crianças liberadas pelo Instituto (a foto da página já é liberada), em linha com o Manual de Boas Práticas para Redes Sociais.
