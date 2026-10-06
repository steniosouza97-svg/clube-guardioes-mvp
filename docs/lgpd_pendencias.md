# Privacidade e LGPD: o que está feito e o que falta

Clube Guardiões do Futuro | Instituto Ebenézer | MVP funcional, semana 10

Este documento separa o que o MVP já garante tecnicamente do que o Instituto precisa definir antes de operar com doadores reais. Não substitui a avaliação do jurídico do Instituto.

## 1. Quais dados pessoais o Clube trata

| Dado | Para quê | Onde fica |
|---|---|---|
| Nome | Identificar o Guardião e personalizar as mensagens | Asaas e banco do painel |
| CPF | Exigido pela Asaas para cadastrar o doador e emitir a cobrança; identificador único contra duplicidade | Número completo: só na Asaas. Banco do painel: só a impressão digital cifrada |
| E-mail (opcional) | Contato e envio da cobrança, quando o doador informa. Se informado, precisa ser válido | Asaas e banco do painel |
| WhatsApp | Envio do Pix mensal, lembretes e notícias de impacto | Asaas e banco do painel |
| Valor, dia e histórico de pagamentos | Operar a doação recorrente e prestar contas | Asaas e banco do painel |
| Registro do consentimento | Comprovar a base legal | Banco do painel |
| Doação única (`doacao_unica`) | Nome, WhatsApp, CPF, e-mail opcional, valor, status e código de convite: os mesmos dados mínimos do Guardião, para gerar o Pix e prestar contas. O CPF fica só como impressão digital HMAC | Asaas e banco do painel |
| Tentativas de entrada na Minha Área (`tentativa_acesso`) | Impressão digital HMAC do WhatsApp, se deu certo e a data. Finalidade única: bloquear a entrada após 5 erros em 15 minutos. Não guarda o telefone nem o CPF digitados | Banco do painel |
| Pausa e motivo de cancelamento | Data de volta da pausa e texto livre do motivo (até 200 caracteres), para operar a assinatura e entender o churn | Asaas e banco do painel |

Não são tratados: dados de cartão, dados sensíveis (art. 5º, II), dados de crianças. O painel não armazena imagens.

## 2. O que o MVP já garante

| Garantia | Como | Teste que comprova |
|---|---|---|
| Consentimento registrado antes de qualquer adesão | Restrição do banco; a adesão sem consentimento é recusada | T02 |
| CPF nunca gravado em texto aberto no banco do painel | Impressão digital HMAC-SHA256 com chave secreta aleatória, guardada em esquema sem acesso externo | T23 e controle negativo 2 |
| Duplicidade barrada pelo CPF | A mesma pessoa não tem duas assinaturas, mesmo com e-mails diferentes | T04, T22 |
| Voluntários não veem o CPF cifrado nem a chave | Permissão por coluna e esquema privado | S10 |
| Visitante anônimo não lê nenhum dado de doador | Segurança por linha e permissões por papel | S01, S04, S09 |
| Só voluntários cadastrados acessam o painel | Lista de voluntários checada pelo banco | S05, S06 |
| Toda gravação passa pelas regras do fluxo | Funções como única porta de escrita | S04, S07 |
| Base de demonstração sem dados reais | E-mails no domínio reservado example.com; CPFs fictícios gravados só cifrados | T20 |
| E-mail não é obrigatório | Guardião e doação única aceitam cadastro sem e-mail; se informado, é validado | T32, E22 |
| Doação única com os mesmos cuidados do Guardião | CPF só como HMAC; o visitante anônimo não lê a tabela; voluntário vê a lista sem o CPF cifrado (`vw_doacoes_unicas`) | T33, S13 |
| Minha Área não expõe dados sensíveis | Entrada só com WhatsApp e CPF corretos; resposta genérica ("dados não conferem"); devolve só primeiro nome, status, valores e histórico, nunca e-mail, telefone ou CPF; bloqueio após 5 erros em 15 minutos | T35, S13, E23 |
| Recibo só para o próprio Guardião | `fn_area_recibo` exige os mesmos dados da entrada; o recibo informa que não há dedução de Imposto de Renda para pessoa física | T38, E23 |

### O conceito de CPF cifrado, em uma frase

O banco guarda uma impressão digital do CPF: o mesmo CPF sempre gera o mesmo código, o que permite barrar duplicidade e responder "este CPF já é Guardião?", mas o código não permite recuperar o número. Pela LGPD, isso é **pseudonimização** (art. 13, §4º): o dado continua sendo pessoal, mas um vazamento do banco não expõe o CPF.

**Limite honesto:** quem tiver acesso de administrador ao banco (a chave em `privado.segredo`) poderia, com esforço computacional, testar CPFs um a um até achar o de um código. Por isso a chave fica fora do alcance da API e o acesso de administrador ao Supabase deve ser restrito a uma ou duas pessoas do Instituto.

## 3. O que falta para operar com doadores reais

| # | Pendência | Artigo da LGPD | Quem resolve | Prioridade |
|---|---|---|---|---|
| L1 | **Política de privacidade** (há uma versão do MVP em `web/privacidade.html`, a validar) publicada na página de adesão: quais dados, para quê, por quanto tempo, com quem são compartilhados (Asaas), como exercer direitos | art. 6º, VI; art. 9º | Instituto e jurídico | Antes de abrir a página ao público |
| L2 | **Canal de atendimento ao titular** (e-mail dedicado) e procedimento para acesso, correção, portabilidade e exclusão, com prazo de resposta | art. 18 | Instituto | Antes de abrir a página ao público |
| L3 | **Encarregado ou canal de contato.** O Instituto provavelmente se enquadra como agente de tratamento de pequeno porte (Resolução CD/ANPD nº 2/2022), que dispensa indicar encarregado, mas exige canal de comunicação | art. 41 | Jurídico confirma o enquadramento | Antes de abrir a página ao público |
| L4 | **Prazo de guarda e descarte:** o que acontece com os dados de quem cancelou. Sugestão: manter o histórico de doações pelo prazo exigido para a prestação de contas e a contabilidade, e anonimizar o contato depois | art. 15 e 16 | Instituto, com o contador | Antes do primeiro cancelamento real |
| L5 | **Procedimento de exclusão** no banco: função que anonimiza nome, e-mail e telefone e remove o CPF cifrado, preservando os valores para a prestação de contas | art. 18, VI | Tecnologia | Junto com L4 |
| L6 | **Registro das operações de tratamento** (inventário simples: dado, finalidade, base legal, local, prazo). A seção 1 deste documento é o ponto de partida | art. 37 | Instituto | Primeiro trimestre de operação |
| L7 | **Contrato e termos com a Asaas** revisados quanto ao papel de cada parte no tratamento dos dados (Asaas como operadora ou controladora) | art. 39 | Jurídico | Antes de ligar a Asaas real |
| L8 | **Plano de resposta a incidente:** quem avisa, em quanto tempo, como comunicar a ANPD e os doadores | art. 48 | Instituto | Primeiro trimestre de operação |
| L9 | **Acesso administrativo restrito** ao Supabase e à Asaas: poucas pessoas, contas nominais com e-mail institucional, autenticação em dois fatores | art. 46 | Instituto | Na passagem do projeto ao Instituto |
| L10 | **Chave do CPF no cofre do Supabase (Vault)** em vez de tabela privada, e rotina de troca da chave documentada | art. 46 | Tecnologia | Antes de operar com doadores reais |
| L11 | **Entrada na Minha Área mais forte.** WhatsApp e CPF são dados que terceiros podem conhecer: aceitável na demonstração com dados sintéticos, fraco para produção. Trocar por código de uso único enviado ao WhatsApp (US06 original) ou link mágico por e-mail. Mitigação atual: bloqueio após 5 erros em 15 minutos, resposta genérica, nenhum dado sensível devolvido | art. 46 | Tecnologia | Antes de operar com doadores reais |
| L12 | **Prazo de guarda de `tentativa_acesso`.** Hoje nada apaga os registros. Sugestão: apagar tentativas com mais de 30 dias por rotina agendada; o bloqueio só usa os últimos 15 minutos | art. 15 e 16 | Tecnologia | Antes de operar com doadores reais |

### Base atual em Pix direto

Os 35 Guardiões de hoje entram no painel com CPF e consentimento colhidos na conversa de convite (DT-15). O consentimento precisa ser registrado antes do cadastro: o banco recusa o cadastro sem ele (T25). O convite deve informar para que o CPF será usado e que a tarifa da Asaas é paga pelo Instituto, não pelo doador.

### Convite e Aviso de Privacidade (jornada da semana 5)

- O link pessoal de convite ("Indique um novo Doador") revela ao visitante só o primeiro nome de quem convidou, e apenas a quem tem o código (T29, S12). Vale para Guardiões e para quem fez doação única. O convite é iniciativa do próprio doador; o banco registra só qual código foi usado.
- A página de adesão tem um Aviso de Privacidade em linguagem simples, ligado ao consentimento, que cobre e-mail opcional, doação única, Minha Área (dados usados para entrar e registro de tentativas), pausa e link de indicação. É uma versão do MVP: o texto oficial depende do jurídico (L1).

### Doação única, Minha Área e recibo

- **Doação única:** mesmos dados mínimos do Guardião (nome, WhatsApp, CPF, e-mail opcional). O CPF é obrigatório pela Asaas e fica só como HMAC. Os prazos de guarda (L4) e a exclusão (L5) precisam cobrir também a tabela `doacao_unica`.
- **Minha Área:** usa WhatsApp e CPF só para conferir a identidade; não os devolve na tela. O registro de tentativas guarda a impressão digital do telefone, não o número. A troca por código de uso único (L11) é a pendência principal antes da produção.
- **Recibo anual:** emitido só para o próprio Guardião, com nome, ano e valores pagos (doações mensais e doações únicas feitas com o mesmo CPF). Não traz CPF completo nem promete dedução de Imposto de Renda. O modelo final do recibo deve ser validado pelo contador do Instituto junto com L4.

### Dado real na base de demonstração

Durante uma validação ao vivo, entraram na base de demonstração dois cadastros com e-mail real. O T20 detectou; os registros, a mensagem associada e as tentativas de acesso do dia foram apagados, e a demonstração recusa e-mail fora de `@example.com` (T39). Lição para a operação real: a base de testes e a de produção devem ser projetos separados no Supabase, e ninguém testa a página de produção com dados de terceiros.

## 4. Síntese

O MVP trata o CPF como a semana 5 definiu, como identificador único, e resolve a tensão entre esse uso e o princípio da necessidade guardando só a impressão digital cifrada. A conformidade completa depende de decisões institucionais (política de privacidade, canal do titular, prazo de guarda) que estão listadas acima com dono e prazo.
