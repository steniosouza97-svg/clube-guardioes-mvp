# Clube Guardiões do Futuro

Sistema de doação recorrente do Instituto de Cultura e Lazer Ebenézer, que atende 120 crianças no Jardim Ângela, em São Paulo. Ele capta novos doadores pessoa física pelo Pix, transforma a doação em vínculo (estrelas, níveis, prestação de contas mensal e indicação pelo WhatsApp) e dá à equipe do Instituto um painel com as métricas e os alertas para manter cada Guardião. É o MVP funcional da semana 10 do MBA Inteli, com banco de dados real, dados sintéticos e testes automatizados.

![Telas do MVP: jornada do doador, área do doador e área do voluntário](docs/telas/00_visao_geral.png)

| Acesse | Endereço |
|---|---|
| Página do doador (MVP no ar) | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html (acesso restrito a voluntários cadastrados) |
| Vídeos demonstrativos | Pasta `Tecnologia/semana 10/Video` do Drive da entrega: "MVP Demo_Doação & Engajamento" e "MVP Area Doador e Area Voluntario" |
| Pacote de entrega | [ENTREGA.md](ENTREGA.md) |

> **Ambiente de demonstração.** A base tem só dados sintéticos e nenhum valor é cobrado. Para testar, deixe o e-mail em branco (ou use um terminado em `@example.com`) e use um CPF fictício, como `900.000.001-75`.

## Sumário

1. [Autoria](#autoria)
2. [Telas do MVP](#telas-do-mvp)
3. [Como instalar e rodar](#como-instalar-e-rodar)
4. [Visão geral da arquitetura](#visão-geral-da-arquitetura)
5. [Decisões técnicas e o valor para o Instituto](#decisões-técnicas-e-o-valor-para-o-instituto)
6. [Testes e evidências](#testes-e-evidências)
7. [Próximos passos](#próximos-passos)
8. [Dados e privacidade](#dados-e-privacidade)
9. [Documentação completa](#documentação-completa)

---

## Autoria

**Grupo 2, MBA Inteli, Módulo 3** (entrega da semana 10, trilha de Tecnologia):

- Allan Oliveira
- Guilherme Souza
- Ivan Hasse
- Stenio Souza

Organização parceira: Instituto de Cultura e Lazer Ebenézer, Jardim Ângela, São Paulo.

---

## Telas do MVP

Capturas do MVP em funcionamento, com dados sintéticos de demonstração.

### 1. Jornada do Doador

Quem chega pela página escolhe ser Guardião (R$ 85 por mês no Pix) ou fazer uma doação única de qualquer valor, conclui em três passos e já sai convidando outra pessoa.

| Página inicial | Convite para o Ouro | Cadastro | Pix |
|:---:|:---:|:---:|:---:|
| <img src="docs/telas/01_inicio.png" width="190" alt="Página inicial"> | <img src="docs/telas/02_convite_ouro.png" width="190" alt="Convite para ser Guardião do Futuro Ouro"> | <img src="docs/telas/03_cadastro.png" width="190" alt="Cadastro em etapas"> | <img src="docs/telas/04_pix.png" width="190" alt="Pagamento por Pix com QR Code"> |
| A causa e o convite para doar todo mês | A trilha das 5 estrelas até o Ouro | Guardião ou doação única; e-mail opcional | QR Code e copia e cola |

| Confirmação | Indique um novo Doador | Doação única |
|:---:|:---:|:---:|
| <img src="docs/telas/05_confirmacao.png" width="190" alt="Confirmação da doação"> | <img src="docs/telas/06_indique_doador.png" width="190" alt="Mensagem de indicação pelo WhatsApp"> | <img src="docs/telas/07_doacao_unica.png" width="190" alt="Doação única de qualquer valor"> |
| Agradecimento e resumo | Mensagem de impacto com link pessoal | R$ 30, R$ 60, R$ 120 ou outro valor |

### 2. Área do Doador (Minha Área)

O Guardião entra com WhatsApp e CPF, vê o nível e quanto falta para o Ouro, o que a doação sustentou mês a mês e o histórico; pode pausar em vez de cancelar e emitir o recibo anual.

| Entrada | Conquista e nível | Jornada até o Ouro |
|:---:|:---:|:---:|
| <img src="docs/telas/08_entrar_minha_area.png" width="190" alt="Entrada da Minha Área"> | <img src="docs/telas/09_minha_area_conquista.png" width="190" alt="Carlos, você já é um Guardião Prata"> | <img src="docs/telas/10_jornada_estrelas.png" width="190" alt="Trilha de estrelas e previsão do Ouro"> |

| Prestação de contas | Histórico e pausa | Recibo anual |
|:---:|:---:|:---:|
| <img src="docs/telas/11_impacto.png" width="190" alt="O que as doações sustentaram"> | <img src="docs/telas/12_historico_pausa.png" width="190" alt="Histórico de doações e opção de pausa"> | <img src="docs/telas/13_recibo.png" width="190" alt="Recibo anual de doações"> |

### 3. Área do Voluntário (painel)

A pessoa dedicada ao Clube acompanha as métricas contra a meta e o custeio, contata quem atrasou o Pix, vê de onde vêm os Guardiões e registra a prestação de contas do mês.

| Resumo | Alerta de churn |
|:---:|:---:|
| <img src="docs/telas/15_painel_resumo.png" width="420" alt="Resumo do painel"> | <img src="docs/telas/16_alerta_churn.png" width="420" alt="Alerta de churn"> |
| Indicadores, meta de 100 Guardiões, custeio coberto e exportação para prestação de contas | Quem atrasou o Pix, por prioridade, com contato pelo WhatsApp |

| Guardiões | Doações únicas |
|:---:|:---:|
| <img src="docs/telas/17_guardioes.png" width="420" alt="Lista de Guardiões"> | <img src="docs/telas/18_doacoes_unicas.png" width="420" alt="Doações únicas"> |
| Busca, consulta de CPF sem revelar o número, nível, pausa e cancelamento | Quem doou uma vez: candidatos a Guardião |

| Canais | Atividades e prestação de contas |
|:---:|:---:|
| <img src="docs/telas/19_canais.png" width="420" alt="Resultado por canal"> | <img src="docs/telas/20_atividades.png" width="420" alt="Atividades e prestação de contas"> |
| Captação e retenção por canal de origem | O que cada atividade sustentou no mês |

| Operação do mês | Entrada do painel |
|:---:|:---:|
| <img src="docs/telas/21_operacao_mes.png" width="420" alt="Operação do mês"> | <img src="docs/telas/14_painel_login.png" width="420" alt="Login do painel"> |
| Cobranças, retorno da Asaas (simulado no MVP) e notícia de impacto | Só voluntários cadastrados entram |

As mesmas telas foram conferidas em celular, tablet e computador: [telas em três tamanhos](docs/diagramas/telas_responsivas.png).

---

## Como instalar e rodar

O passo a passo completo, com o resultado esperado em cada etapa e um roteiro de validação de 20 passos, está no **[guia de instalação e validação](INSTALACAO.md)**.

### Requisitos e versões

| Item | Versão | Para quê |
|---|---|---|
| Conta no Supabase | Plano gratuito (PostgreSQL 17) | Banco de dados, API e login do painel |
| Navegador | Chrome, Edge ou Firefox atuais | Usar a interface e o painel do Supabase |
| `supabase-js` | 2.117.2, já incluída em `web/vendor/` | Ligação da interface com o Supabase; não precisa instalar |
| Publicação da interface | Netlify Drop ou GitHub Pages (sem instalação), ou Python 3 para rodar localmente | Servir a pasta `web/` |
| Testes locais (opcional) | PostgreSQL 14 ou superior e terminal bash | Rodar `tests/rodar_testes.sh` sem Supabase |
| Teste de interface (opcional) | PostgREST 12, Python 3 e Playwright 1.56 | Rodar `tests/e2e/rodar_e2e.sh` |

### Resumo da instalação

1. Criar um projeto gratuito no Supabase (região São Paulo).
2. No **SQL Editor**, rodar na ordem: `db/01_schema.sql`, `db/02_funcoes.sql`, `db/03_views.sql`, `db/04_dados_referencia.sql`, `db/05_dados_sinteticos.sql` (só na demonstração), `db/06_supabase_seguranca.sql`, `tests/qa_testes.sql` e `tests/qa_seguranca.sql`.
3. Criar o usuário do voluntário em **Authentication** e autorizá-lo com `insert into voluntario (email, nome) values (...)`; desligar o cadastro público.
4. Copiar a **Project URL** e a **Publishable key** para `web/config.js`. A chave secreta e a chave da Asaas nunca vão para a interface.
5. Publicar a pasta `web/` (Netlify Drop, GitHub Pages ou `python -m http.server` dentro de `web/`).

### Como verificar que funcionou

| Verificação | Resultado esperado |
|---|---|
| Contagem da base | 305 Guardiões, 271 ativos, 4 pausados, 48 doações únicas |
| `select * from qa.fn_rodar_testes();` | 39 testes `PASS`, nenhuma `FALHA` |
| `select * from qa.fn_testes_seguranca();` | 13 testes `PASS`, nenhuma `FALHA` |
| Página e painel | Roteiro V1 a V20 do [guia](INSTALACAO.md#8-roteiro-de-validação-20-a-30-min) |

---

## Visão geral da arquitetura

### Tela, servidor e banco

```mermaid
flowchart LR
  subgraph Navegador["Navegador (front-end, pasta web/)"]
    P["Página do doador<br/>e Minha Área<br/>index.html"]
    V["Painel do voluntário<br/>painel.html"]
  end
  subgraph Supabase["Supabase (back-end gerenciado)"]
    API["API REST automática<br/>(PostgREST)"]
    AUTH["Login do voluntário<br/>(Supabase Auth)"]
    subgraph DB["PostgreSQL"]
      F["Funções do fluxo<br/>(única porta de escrita)"]
      T["13 tabelas<br/>com regras e RLS"]
      W["7 views de métricas"]
    end
  end
  ASAAS["Asaas<br/>(gateway de Pix)"]
  P -- "supabase-js, chave publicável" --> API
  V -- "supabase-js + login" --> AUTH
  V --> API
  API --> F
  API --> W
  F --> T
  W --> T
  ASAAS -. "webhook de pagamento<br/>(simulado no MVP)" .-> F
```

- **Front-end:** HTML, CSS e JavaScript sem etapa de build, hospedados como arquivos estáticos (GitHub Pages).
- **Back-end:** o próprio Supabase. A API é gerada a partir do banco; não há servidor próprio para manter.
- **Regra de negócio:** em funções SQL. A interface só lê views e chama funções; nenhum usuário grava direto nas tabelas.
- **Pagamento:** na Asaas, gateway que o Instituto já contratou. No MVP, os avisos de "Pix pago" e "Pix vencido" são simulados com os nomes reais dos eventos e passam pela mesma função que o webhook real vai chamar.

### Estrutura de pastas

```
clube-guardioes-mvp/
├── README.md                 porta de entrada (este arquivo)
├── INSTALACAO.md             guia de instalação e validação do zero
├── ENTREGA.md                pacote de entrega da semana 10
├── CONTRIBUTING.md           como manter e alterar o MVP com segurança
├── db/                       banco de dados, na ordem de instalação
│   ├── 01_schema.sql         tabelas, regras e índices
│   ├── 02_funcoes.sql        fluxo: adesão, cobrança, Pix, régua, Minha Área
│   ├── 03_views.sql          métricas do painel
│   ├── 04_dados_referencia.sql  parâmetros e canais
│   ├── 05_dados_sinteticos.sql  gerador de dados fictícios (só demonstração)
│   └── 06_supabase_seguranca.sql  regras de acesso (RLS e permissões)
├── web/                      interface (front-end)
│   ├── index.html            página do doador, Minha Área e recibo
│   ├── painel.html           painel do voluntário
│   ├── privacidade.html      Aviso de Privacidade
│   ├── config.js             URL e chave publicável do Supabase
│   ├── css/  js/  img/       estilo, lógica das telas e imagens
│   └── vendor/               biblioteca supabase-js
├── tests/                    testes do banco (qa_*.sql) e da interface (e2e/)
├── evidencias/               resultados das execuções de teste
├── docs/                     documentação técnica, diagramas e telas
└── .github/workflows/        publicação da interface e rotina do Supabase
```

### Entidades do banco e relações

![Diagrama entidade-relacionamento](docs/diagramas/diagrama_banco_de_dados_erd.png)

| Grupo | Tabelas |
|---|---|
| Doador e recorrência | `guardiao` (o Guardião, com CPF só cifrado), `assinatura` (doação mensal, ativa, pausada ou cancelada), `cobranca` (o Pix de cada mês) |
| Pagamento | `evento_gateway` (avisos da Asaas, com proteção contra repetição) |
| Doação única | `doacao_unica` |
| Relacionamento e prestação de contas | `comunicacao` (boas-vindas, agradecimento, lembrete, notícia de impacto), `atividade` e `impacto_mensal` (o que cada atividade sustentou no mês) |
| Configuração e acesso | `origem` (canais de captação), `parametro` (valor do Guardião, metas, limites), `voluntario` (quem acessa o painel), `tentativa_acesso` (bloqueio da Minha Área), `privado.segredo` (chave do CPF, sem acesso externo) |

O desenho completo, com permissões, funções e dicionário de dados, está em [docs/diagramas/diagrama_banco_de_dados.pdf](docs/diagramas/diagrama_banco_de_dados.pdf) e em [docs/modelo_de_dados.md](docs/modelo_de_dados.md).

---

## Decisões técnicas e o valor para o Instituto

Cada escolha técnica explicada também pelo valor que gera para a organização. O registro completo, com alternativas e consequências, está em [docs/decisoes_tecnicas.md](docs/decisoes_tecnicas.md).

| Decisão técnica | Razão técnica | Valor para o Instituto | Alternativa considerada |
|---|---|---|---|
| **Guardar os dados em um banco de dados** (PostgreSQL no Supabase) | Integridade garantida por regras: um CPF por Guardião, um Pix por mês, todo pagamento rastreável | Métricas confiáveis (Guardiões ativos, churn, custeio coberto) e prestação de contas com dado, que é o que o financiador cobra. Sem o banco, voltaria à planilha manual: sem histórico confiável, sem alerta de quem atrasou e sem como mostrar resultado | Google Sheets com Apps Script, mais familiar, mas sem integridade nem testes automáticos |
| **Separar a tela (front-end) do servidor (back-end)** | A interface só exibe e chama funções; as regras ficam no banco, testadas de forma independente | Trocar textos, cores ou até a tela inteira não mexe em regra nenhuma; dá para ligar outro canal (checkout da Asaas, app) reaproveitando o mesmo banco | Sistema único com tela e regra misturadas, mais difícil de manter por voluntários |
| **Validar os dados antes de salvar** | CPF com dígito verificador, e-mail válido, consentimento LGPD obrigatório, valor mínimo, CPF duplicado barrado, e-mail real recusado na demonstração | Evita doador duplicado (contaria o mesmo Guardião duas vezes e mandaria mensagem em dobro), cobrança errada e cadastro sem consentimento, que é risco legal pela LGPD | Validar só na tela, que pode ser contornada |
| **Versionar o projeto em um repositório** (GitHub público) | Todo o histórico de mudanças, migrações do banco numeradas, testes e publicação automática da interface | Nada se perde e o Instituto não depende dos autores: qualquer pessoa reinstala do zero seguindo o guia e sabe o que mudou, quando e por quê | Arquivos soltos em pastas, sem histórico |
| **Asaas como gateway de Pix** | Sem mensalidade; R$ 1,99 por Pix e R$ 0,55 por mensagem | Já contratada pelo Instituto; custo de R$ 3,09 por Guardião ao mês, que nasce junto com a receita | Plataforma completa com mensalidade, que consumiria 28,9% da arrecadação atual |
| **CPF guardado só cifrado** | Impressão digital HMAC-SHA256 com chave secreta | Identifica o doador e barra duplicidade sem expor o CPF de ninguém em caso de vazamento | CPF em texto aberto ou não pedir CPF |
| **Interface sem etapa de build** | HTML, CSS e JavaScript puros, biblioteca copiada para o projeto | Hospedagem gratuita e manutenção por quem tem noções básicas de web, sem ferramentas que envelhecem | React ou Next.js, que exigem build e atualização constante de dependências |

---

## Testes e evidências

| Camada | O que cobre | Resultado |
|---|---|---|
| Fluxo (`qa.fn_rodar_testes()`) | Adesão, cobrança, Pix pago e vencido, recuperação, cancelamento, Minha Área, pausa, estrelas, recibo, dados sintéticos e integridade | 39 de 39 aprovados no Supabase e localmente |
| Acesso (`qa.fn_testes_seguranca()`) | Visitante anônimo, conta sem cadastro de voluntário, voluntário, CPF e chave protegidos | 13 de 13 aprovados |
| Interface (Playwright) | 25 passos no navegador, do cadastro ao painel | 25 de 25 aprovados |
| Telas em três tamanhos | Celular, tablet e computador, sem rolagem lateral | 12 de 12 aprovados |
| Controles negativos | Defeitos introduzidos de propósito são detectados pela suíte | 2 de 2 detectados |
| Usuário real | Teste ao vivo com pessoa de fora do projeto | Registrado em [teste com usuários](docs/teste_com_usuarios.md) |

Os testes do banco rodam num bloco desfeito ao final e podem ser repetidos a qualquer momento. Detalhes e evidências em [docs/casos_de_teste.md](docs/casos_de_teste.md) e na pasta `evidencias/`.

---

## Próximos passos

### O que falta para começar a usar com doadores reais

1. **Conta do Instituto no Supabase**, com e-mail institucional, e instalação seguindo o [guia](INSTALACAO.md) sem o arquivo 5 (dados sintéticos).
2. **Ligar a Asaas de verdade:** uma Edge Function do Supabase recebe o webhook e a página encaminha para o checkout da Asaas ([DT-04](docs/decisoes_tecnicas.md)).
3. **Trocar a entrada da Minha Área** por código de uso único no WhatsApp ou link por e-mail ([DT-18](docs/decisoes_tecnicas.md)).
4. **Fechar as pendências de LGPD** (política de privacidade, canal do titular, prazo de guarda, exclusão): [docs/lgpd_pendencias.md](docs/lgpd_pendencias.md).
5. **Desligar o modo de demonstração:** `demonstracao: false` em `web/config.js` e `modo_demonstracao = 0` no banco.
6. **Designar a pessoa dedicada ao Clube** (80 horas por mês) e cadastrá-la como voluntária. A rotina de operação está em [docs/operacao.md](docs/operacao.md).

### Melhorias por prioridade

| Prioridade | Melhoria |
|---|---|
| Alta | Webhook e checkout reais da Asaas, incluindo doação única como cobrança avulsa e pausa espelhada na assinatura |
| Alta | Login da Minha Área por código de uso único |
| Média | Modelo oficial do recibo anual, validado pelo contador do Instituto |
| Média | Chave do CPF no cofre do Supabase (Vault) |
| Baixa | Doação de pessoa jurídica e comprovação fiscal corporativa |
| Baixa | Vínculo individual da doação a uma atividade específica |

### Riscos e limitações conhecidos

- **Pagamento simulado:** no MVP, os avisos da Asaas são simulados; nenhum valor é cobrado.
- **Entrada da Minha Área por WhatsApp e CPF:** adequada para demonstração com dados sintéticos, não para doadores reais.
- **Plano gratuito do Supabase pausa por inatividade:** o projeto é restaurado sem perda de dados; o uso frequente do painel evita a pausa e, em operação, o plano pago elimina o risco.
- **Dependência de uma pessoa:** mitigada por processo documentado, régua automática e um segundo voluntário a partir da terceira fase do plano.
- **Base de demonstração maior que o plano:** 275 Guardiões no mês 12, contra 164 previstos, de propósito, para exercitar o painel com volume.
- **Sem dedução de Imposto de Renda:** doação direta ao Instituto não é dedutível para pessoa física, e a página e o recibo dizem isso.
- **Fora do escopo do MVP:** CRM próprio, motor de campanhas e sistema de embaixadores, que o Instituto não conseguiria manter sem os autores.

---

## Dados e privacidade

- **Dados sintéticos:** nomes aleatórios, e-mails no domínio reservado `example.com` e telefones fictícios. Nenhum dado real de doador está neste repositório; o teste T20 verifica isso. Enquanto o modo de demonstração estiver ligado, o banco recusa e-mail real.
- **Sem senhas nem chaves secretas no repositório:** `web/config.js` traz só a URL e a chave publicável do Supabase, feita para ficar no navegador; quem protege os dados são as regras do banco. A chave secreta do Supabase e a chave da Asaas nunca entram no projeto.
- **CPF cifrado:** o banco guarda só a impressão digital do CPF; o número completo fica na Asaas ([DT-14](docs/decisoes_tecnicas.md)).
- **Imagens:** só fotos do banco liberado pelo Instituto, conforme sua política e o Manual de Boas Práticas para Redes Sociais.

---

## Documentação completa

| Documento | Conteúdo |
|---|---|
| [INSTALACAO.md](INSTALACAO.md) | Instalação do zero e roteiro de validação |
| [ENTREGA.md](ENTREGA.md) | Como o MVP atende a cada exigência do enunciado |
| [docs/operacao.md](docs/operacao.md) | Rotina de operação, publicação, passagem ao Instituto e passo para produção |
| [docs/rastreabilidade_semana5.md](docs/rastreabilidade_semana5.md) | Cada tela do protótipo da semana 5 e onde está no MVP |
| [docs/user_stories.md](docs/user_stories.md) | User stories com critérios de aceite ligados aos testes |
| [docs/modelo_de_dados.md](docs/modelo_de_dados.md) e [desenho do banco](docs/diagramas/diagrama_banco_de_dados.pdf) | Tabelas, relações, views, permissões e dicionário de dados |
| [docs/decisoes_tecnicas.md](docs/decisoes_tecnicas.md) | Decisões numeradas, com alternativas e consequências |
| [docs/casos_de_teste.md](docs/casos_de_teste.md) | Cenários, resultados, defeitos encontrados e evidências |
| [docs/teste_com_usuarios.md](docs/teste_com_usuarios.md) | Teste com usuário real: hipóteses, participante e aprendizados |
| [docs/lgpd_pendencias.md](docs/lgpd_pendencias.md) | O que o MVP garante e as pendências para operar com doadores reais |
| [docs/roteiro_video.md](docs/roteiro_video.md) | Roteiro do vídeo demonstrativo |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Como alterar o código e o banco com segurança |
