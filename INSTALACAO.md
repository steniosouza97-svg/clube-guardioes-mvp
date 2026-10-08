# Guia de instalação e validação do MVP

Clube Guardiões do Futuro | Instituto Ebenézer | MVP funcional, semana 10

Este guia instala o MVP do zero em uma conta nova do Supabase e confere, passo a passo, que tudo funciona. Serve para qualquer integrante do grupo validar a entrega e, depois, para o Instituto instalar a versão dele. Cada passo diz o que fazer e o que deve aparecer na tela. Se o resultado for diferente, pare e anote na ficha do final.

Tempo estimado: 60 a 75 minutos. Não é preciso saber programar.

---

## 1. O que você precisa

| Item | Detalhe |
|---|---|
| Arquivo do projeto | `clube-guardioes-mvp_08-10.zip` (pasta `Tecnologia/semana 10` do Drive) ou o repositório https://github.com/steniosouza97-svg/clube-guardioes-mvp (botão **Code > Download ZIP**) |
| Conta no Supabase | Gratuita, criada com o **seu próprio e-mail** em https://supabase.com. Para o Instituto, usar o e-mail institucional |
| Navegador | Chrome, Edge ou Firefox atualizados |
| Editor de texto | Bloco de Notas, VS Code ou similar, para abrir os arquivos `.sql` e editar um arquivo `.js` |
| Para abrir a interface (escolha uma) | **Opção A:** nada a instalar, usa o Netlify Drop no navegador. **Opção B:** Python 3 instalado no computador |

Descompacte o ZIP em uma pasta fácil de achar, por exemplo `Documentos\clube-guardioes-mvp`. Os arquivos usados neste guia estão nas pastas `db`, `tests` e `web`.

**Regra da demonstração:** use só dados fictícios. E-mail em branco ou terminado em `@example.com`; CPFs fictícios, como os deste guia. O banco recusa e-mail real enquanto estiver em modo de demonstração.

---

## 2. Criar o projeto no Supabase (5 min)

1. Entre em https://supabase.com/dashboard com a sua conta.
2. Clique em **New project**.
3. Preencha:
   - **Organization:** a sua (criada no cadastro);
   - **Project name:** `clube-guardioes-teste`;
   - **Database password:** crie uma senha forte e guarde (não será usada neste guia, mas é a senha do banco);
   - **Region:** South America (São Paulo);
   - **Plan:** Free.
4. Se aparecerem opções de segurança, mantenha o **Data API** ligado. As demais podem ficar no padrão: o arquivo de segurança do projeto liga as regras de acesso de cada tabela.
5. Clique em **Create new project** e aguarde de 1 a 3 minutos, até o painel do projeto abrir.

**Resultado esperado:** o painel do projeto aberto, com o menu lateral (Table Editor, SQL Editor, Authentication...).

---

## 3. Instalar o banco de dados (15 min)

Tudo neste passo acontece no **SQL Editor** (menu lateral). Para cada arquivo da tabela abaixo, **na ordem**:

1. No SQL Editor, clique em **+ New query** (ou no ícone de nova aba).
2. Abra o arquivo no editor de texto, selecione tudo (**Ctrl+A**) e copie (**Ctrl+C**).
3. Cole no SQL Editor (**Ctrl+V**) e clique em **Run** (ou **Ctrl+Enter**).
4. Se aparecer um aviso de "operação potencialmente destrutiva", clique em **Run this query**: os arquivos só criam o que é do projeto.
5. Confira o resultado esperado antes de passar ao próximo arquivo.

| # | Arquivo | O que faz | Resultado esperado |
|---|---|---|---|
| 1 | `db/01_schema.sql` | Tabelas, regras e índices | `Success. No rows returned` |
| 2 | `db/02_funcoes.sql` | Funções do fluxo (adesão, cobrança, Minha Área...) | `Success. No rows returned` |
| 3 | `db/03_views.sql` | Métricas do painel | `Success. No rows returned` |
| 4 | `db/04_dados_referencia.sql` | Parâmetros e canais | `Success. No rows returned` |
| 5 | `db/05_dados_sinteticos.sql` | Cria e roda o gerador de dados fictícios | Uma linha com o texto `305 Guardiões (271 ativos, 4 pausados), ... 48 doações únicas ...` |
| 6 | `db/06_supabase_seguranca.sql` | Regras de acesso | `Success. No rows returned` |
| 7 | `tests/qa_testes.sql` | Instala os testes do fluxo | `Success. No rows returned` |
| 8 | `tests/qa_seguranca.sql` | Instala os testes de acesso | `Success. No rows returned` |

Não pule nem inverta arquivos: cada um usa o que o anterior criou. Se um deles der erro, veja a seção 9.

**Conferência da base.** Em uma nova query, rode:

```sql
select count(*) as guardioes,
       (select count(*) from assinatura where status = 'ativa')   as ativos,
       (select count(*) from assinatura where status = 'pausada') as pausados,
       (select count(*) from doacao_unica)                         as doacoes_unicas
from guardiao;
```

**Resultado esperado:** `305 | 271 | 4 | 48`.

---

## 4. Rodar os testes automáticos (5 min)

Em uma nova query, rode cada linha separadamente:

```sql
select * from qa.fn_rodar_testes();
```

**Resultado esperado:** 41 linhas. 39 começam com `PASS` (T01 a T39) e 2 com `INFO`. **Nenhuma** linha com `FALHA`.

```sql
select * from qa.fn_testes_seguranca();
```

**Resultado esperado:** 15 linhas. 14 começam com `PASS` (S01 a S13; o S13 tem duas linhas) e 1 com `INFO`. **Nenhuma** linha com `FALHA`.

Os testes desfazem tudo ao final: podem ser repetidos quantas vezes quiser. Guarde a evidência: no resultado de cada consulta, use **Export > CSV** (ou tire um print) e salve como `testes_fluxo.csv` e `testes_acesso.csv`.

---

## 5. Criar o acesso do voluntário ao painel (5 min)

1. Menu **Authentication > Users > Add user > Create new user**.
2. Preencha um e-mail de teste, por exemplo `voluntario.teste@example.com`, e uma senha. Marque **Auto Confirm User**. Clique em **Create user**.
3. No **SQL Editor**, autorize esse e-mail como voluntário (o e-mail deve ser idêntico, em minúsculas):

   ```sql
   insert into voluntario (email, nome) values ('voluntario.teste@example.com', 'Voluntário de Teste');
   ```

   **Resultado esperado:** `Success. No rows returned`.
4. Menu **Authentication > Sign In / Providers** (em algumas versões, **Providers** ou **Settings**): desligue **Allow new users to sign up** e salve. Assim ninguém cria conta sozinho; criar conta, de todo modo, não dá acesso a dados.

---

## 6. Ligar a interface ao seu projeto (5 min)

1. No Supabase, menu **Project Settings > API Keys**. Copie a **Publishable key** (começa com `sb_publishable_`).
   - **Nunca** copie a **Secret key** (`sb_secret_...`) nem a antiga `service_role`: elas não podem ir para a interface.
2. Copie a **Project URL**: em **Project Settings > Data API**, ou no botão **Connect** do topo. Tem o formato `https://xxxxxxxx.supabase.co`.
3. No editor de texto, abra `web/config.js` e troque **só** as duas linhas abaixo pelos valores do seu projeto, mantendo as aspas:

   ```js
   supabaseUrl: "https://SEU-PROJETO.supabase.co",
   supabaseKey: "sb_publishable_SUA-CHAVE",
   ```

   Não mexa em `demonstracao: true` nem em `guardiaoDemo`: o Guardião de demonstração é criado igual em qualquer instalação. Salve o arquivo.

---

## 7. Abrir a interface (5 min)

Escolha uma opção.

**Opção A, sem instalar nada (Netlify Drop).**
1. Abra https://app.netlify.com/drop.
2. Arraste a **pasta `web`** inteira (não o ZIP) para a área indicada.
3. Em alguns segundos aparece um endereço do tipo `https://nome-aleatorio.netlify.app`. Esse é o seu site de teste. Se o Netlify pedir login, crie uma conta gratuita.

**Opção B, no próprio computador (Python 3).**
1. Abra o terminal (no Windows, **Prompt de Comando** ou **PowerShell**) dentro da pasta `web`.
2. Rode `python -m http.server 8000` (no Mac ou Linux, `python3 -m http.server 8000`).
3. Abra no navegador http://localhost:8000. Deixe o terminal aberto enquanto testa.

Não abra o `index.html` com duplo clique: a página precisa ser servida por um endereço `http`.

**Resultado esperado:** a página do Clube Guardiões do Futuro, com a faixa amarela de "Ambiente de demonstração" no topo. O painel fica no mesmo endereço, terminando em `/painel.html`.

---

## 8. Roteiro de validação (20 a 30 min)

Faça na ordem e marque cada passo na ficha da seção 10. Os dados abaixo são fictícios e foram escolhidos para não colidir com a base de demonstração.

### Página do doador

| # | O que fazer | O que deve acontecer |
|---|---|---|
| V1 | Abrir a página | Página carrega com foto, a oferta "Guardião R$ 85/mês" e a "Doação única"; faixa de demonstração no topo |
| V2 | Clicar em **Quero participar**; preencher nome `Teste Validação`, WhatsApp `(11) 97777-0901`, CPF `900.000.001-75`, e-mail `teste@gmail.com`, marcar o consentimento; **Continuar para o pagamento** | Mensagem pedindo e-mail terminado em `@example.com` ou em branco; nada é gravado |
| V3 | Apagar o e-mail (deixar **em branco**) e clicar de novo em **Continuar para o pagamento** | Tela do Pix com QR Code e o valor R$ 85,00 |
| V4 | Na tela do Pix, clicar em **Já paguei** | Confirmação "Obrigado(a), Teste!" com o resumo da doação |
| V5 | Clicar em **Indique um novo Doador** | Abre o WhatsApp com uma mensagem de impacto e um link pessoal. **Não envie a ninguém** |
| V6 | Voltar ao início, **Fazer uma doação única**, valor **Outro** `30`, CPF `900.000.002-56`, sem e-mail; **Já paguei** | Confirmação de doação única de R$ 30,00 |
| V7 | Tentar virar Guardião de novo com o CPF `900.000.001-75` | Mensagem de que o CPF já é de um Guardião ativo |

### Minha Área do Guardião

| # | O que fazer | O que deve acontecer |
|---|---|---|
| V8 | No topo, **Minha Área** > **Entrar como Guardião de demonstração** | "Carlos, você já é um Guardião Prata!", 4 estrelas, quanto falta para o Ouro, linha do tempo de impacto e histórico |
| V9 | Em "Precisa de um tempo?", escolher **Pausar 1 mês** no seletor e clicar em **Pausar**; depois clicar em **Retomar** | Situação muda para Pausada (com a data de volta) e volta para Ativa |
| V10 | Clicar em **Emitir recibo de 2026**; depois em **Voltar para minha Área** | Recibo anual em tela própria, com os valores pagos, a frase de que não há dedução de Imposto de Renda e o botão **Imprimir ou salvar em PDF** |
| V11 | Clicar em **Sair** | Sai da Minha Área e volta para a página inicial |

### Painel do voluntário

| # | O que fazer | O que deve acontecer |
|---|---|---|
| V12 | Abrir `/painel.html` e entrar com o e-mail e a senha criados na seção 5 | Aba **Resumo** com os indicadores e dois gráficos. "Guardiões no Clube" mostra **276** (os 275 ativos e pausados da base, mais o Guardião de V2) |
| V13 | Aba **Guardiões**: buscar `Teste Validação` | O Guardião de V2 e V3 aparece, com o canal de origem |
| V14 | Na aba **Guardiões**, no campo **Este CPF já é Guardião?**, digitar `900.000.001-75` e clicar em **Consultar** | Mostra "Ativo, Teste Validação, R$ 85,00", sem exibir o número do CPF em lugar nenhum |
| V15 | Aba **Doações únicas** | A doação de R$ 30 de V6 aparece |
| V16 | Aba **Operação do mês**: **Gerar cobranças do mês** e depois **Simular pagamentos do mês** | Mensagens com o total de cobranças geradas e quantas foram pagas e quantas ficaram em atraso |
| V17 | Aba **Alerta de churn** | Lista de quem está com Pix vencido, com prioridade e botão de WhatsApp |
| V18 | Aba **Resumo**: **Baixar métricas mensais (CSV)** | Baixa um arquivo CSV com as métricas por mês |
| V19 | Abrir o endereço do site no celular | A página cabe na tela, sem rolar para o lado |
| V20 | No SQL Editor, rodar de novo os dois testes da seção 4 | Continuam todos `PASS`, sem `FALHA` |

---

## 9. Se algo der errado

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| Erro `relation ... does not exist` ou `function ... does not exist` ao rodar um arquivo | Um arquivo anterior não rodou ou rodou fora de ordem | Conferir a ordem da seção 3; rodar de novo o arquivo que falhou e os seguintes |
| O arquivo 5 diz que a base já tem dados | O gerador já rodou uma vez | Normal se você repetiu o arquivo; a base já está carregada. Siga para o 6 |
| A página abre mas não carrega nada, ou dá erro ao enviar | `config.js` com URL ou chave erradas, ou projeto pausado | Conferir as duas linhas do `config.js` (seção 6) e se o projeto está ativo no Supabase. Na opção A, arrastar a pasta `web` de novo depois de editar |
| Painel diz "Seu usuário não está cadastrado como voluntário" | E-mail do login diferente do inserido na tabela `voluntario` | Rodar de novo o `insert` da seção 5 com o e-mail exato, em minúsculas |
| Login do painel recusado | Usuário sem confirmação | Em Authentication > Users, conferir se o usuário está confirmado (Auto Confirm User) |
| Mensagem "Ambiente de demonstração: use um e-mail terminado em @example.com" | Trava de proteção de dados | Esperado. Deixe o e-mail em branco ou use `@example.com` |
| Projeto aparece como **Paused** | O plano gratuito pausa projetos sem uso | Clicar em **Restore project** e aguardar |

---

## 10. Ficha de validação

Preencha e devolva ao grupo junto com os arquivos `testes_fluxo.csv` e `testes_acesso.csv` (ou prints).

| Campo | Registro |
|---|---|
| Quem validou | |
| Data e horário | |
| Computador e sistema (Windows, Mac, Linux) | |
| Navegador | |
| Opção da seção 7 (A Netlify ou B Python) | |

| Passo | OK? | Observação |
|---|---|---|
| 2. Projeto criado | | |
| 3. Oito arquivos rodaram sem erro | | |
| 3. Conferência: 305, 271, 4, 48 | | |
| 4. Fluxo: 39 PASS, sem FALHA | | |
| 4. Acesso: 13 testes PASS, sem FALHA | | |
| 5. Voluntário criado e cadastro público desligado | | |
| 6. `config.js` apontando para o seu projeto | | |
| 7. Página abre com a faixa de demonstração | | |
| V1 a V7 (página do doador) | | |
| V8 a V11 (Minha Área) | | |
| V12 a V18 (painel) | | |
| V19 (celular) | | |
| V20 (testes repetidos) | | |

---

## 11. Depois da validação

- **Para quem validou:** o projeto de teste pode ser apagado ou deixado pausado; ele só tem dados fictícios.
- **Para o Instituto, na operação real:** seguir este mesmo guia com a conta institucional, com três diferenças: **não** rodar o arquivo 5 (dados sintéticos); em `web/config.js`, usar `demonstracao: false`; e, no SQL Editor, desligar o modo de demonstração com `update parametro set valor = 0 where chave = 'modo_demonstracao';`. Antes de receber doadores reais, ver "Passo para produção" em `docs/operacao.md` e as pendências de LGPD em `docs/lgpd_pendencias.md`.

## Validação local (opcional, para quem tem PostgreSQL)

Quem tem PostgreSQL 14 ou superior e um terminal bash (Linux, Mac ou Git Bash no Windows) pode rodar a instalação completa e os testes num banco local, sem Supabase:

```bash
export PGHOST=localhost PGPORT=5432 PGUSER=postgres
./tests/rodar_testes.sh
```

**Resultado esperado:** `== RESULTADO: todos os testes passaram`, com a evidência gravada em `evidencias/testes_local_<data>.log`. Os testes de acesso só rodam se o banco tiver os papéis `anon` e `authenticated`, que o Supabase já cria.
