# Privacidade e LGPD: o que está feito e o que falta

Clube Guardiões do Começo | Instituto Ebenézer | registro de 28/09/2026

Este documento separa o que o MVP já garante tecnicamente do que o Instituto precisa definir antes de operar com doadores reais. Não substitui a avaliação do jurídico do Instituto.

## 1. Quais dados pessoais o Clube trata

| Dado | Para quê | Onde fica |
|---|---|---|
| Nome | Identificar o Guardião e personalizar as mensagens | Asaas e banco do painel |
| CPF | Exigido pela Asaas para cadastrar o doador e emitir a cobrança; identificador único contra duplicidade | Número completo: só na Asaas. Banco do painel: só a impressão digital cifrada |
| E-mail | Contato e envio da cobrança | Asaas e banco do painel |
| WhatsApp | Envio do Pix mensal, lembretes e notícias de impacto | Asaas e banco do painel |
| Valor, dia e histórico de pagamentos | Operar a doação recorrente e prestar contas | Asaas e banco do painel |
| Registro do consentimento | Comprovar a base legal | Banco do painel |

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

### O conceito de CPF cifrado, em uma frase

O banco guarda uma impressão digital do CPF: o mesmo CPF sempre gera o mesmo código, o que permite barrar duplicidade e responder "este CPF já é Guardião?", mas o código não permite recuperar o número. Pela LGPD, isso é **pseudonimização** (art. 13, §4º): o dado continua sendo pessoal, mas um vazamento do banco não expõe o CPF.

**Limite honesto:** quem tiver acesso de administrador ao banco (a chave em `privado.segredo`) poderia, com esforço computacional, testar CPFs um a um até achar o de um código. Por isso a chave fica fora do alcance da API e o acesso de administrador ao Supabase deve ser restrito a uma ou duas pessoas do Instituto.

## 3. O que falta para operar com doadores reais

| # | Pendência | Artigo da LGPD | Quem resolve | Prioridade |
|---|---|---|---|---|
| L1 | **Política de privacidade** publicada na página de adesão: quais dados, para quê, por quanto tempo, com quem são compartilhados (Asaas), como exercer direitos | art. 6º, VI; art. 9º | Instituto e jurídico | Antes de abrir a página ao público |
| L2 | **Canal de atendimento ao titular** (e-mail dedicado) e procedimento para acesso, correção, portabilidade e exclusão, com prazo de resposta | art. 18 | Instituto | Antes de abrir a página ao público |
| L3 | **Encarregado ou canal de contato.** O Instituto provavelmente se enquadra como agente de tratamento de pequeno porte (Resolução CD/ANPD nº 2/2022), que dispensa indicar encarregado, mas exige canal de comunicação | art. 41 | Jurídico confirma o enquadramento | Antes de abrir a página ao público |
| L4 | **Prazo de guarda e descarte:** o que acontece com os dados de quem cancelou. Sugestão: manter o histórico de doações pelo prazo exigido para a prestação de contas e a contabilidade, e anonimizar o contato depois | art. 15 e 16 | Instituto, com o contador | Antes do primeiro cancelamento real |
| L5 | **Procedimento de exclusão** no banco: função que anonimiza nome, e-mail e telefone e remove o CPF cifrado, preservando os valores para a prestação de contas | art. 18, VI | Tecnologia | Junto com L4 |
| L6 | **Registro das operações de tratamento** (inventário simples: dado, finalidade, base legal, local, prazo). A seção 1 deste documento é o ponto de partida | art. 37 | Instituto | Primeiro trimestre de operação |
| L7 | **Contrato e termos com a Asaas** revisados quanto ao papel de cada parte no tratamento dos dados (Asaas como operadora ou controladora) | art. 39 | Jurídico | Antes de ligar a Asaas real |
| L8 | **Plano de resposta a incidente:** quem avisa, em quanto tempo, como comunicar a ANPD e os doadores | art. 48 | Instituto | Primeiro trimestre de operação |
| L9 | **Acesso administrativo restrito** ao Supabase e à Asaas: poucas pessoas, contas nominais com e-mail institucional, autenticação em dois fatores | art. 46 | Instituto | Na passagem do projeto ao Instituto |
| L10 | **Chave do CPF no cofre do Supabase (Vault)** em vez de tabela privada, e rotina de troca da chave documentada | art. 46 | Tecnologia | Antes de operar com doadores reais |

### Base atual em Pix direto

Os 35 Guardiões de hoje entram no painel com CPF e consentimento colhidos na conversa de convite (DT-15). O consentimento precisa ser registrado antes do cadastro: o banco recusa o cadastro sem ele (T25). O convite deve informar para que o CPF será usado e que a tarifa da Asaas é paga pelo Instituto, não pelo doador.

## 4. O que dizer à banca

O MVP trata o CPF como a semana 5 definiu, como identificador único, e resolve a tensão entre esse uso e o princípio da necessidade guardando só a impressão digital cifrada. A conformidade completa depende de decisões institucionais (política de privacidade, canal do titular, prazo de guarda) que estão listadas acima com dono e prazo.
