# Entrega da semana 10: trilha de Tecnologia

Clube Guardiões do Futuro | Instituto de Cultura e Lazer Ebenézer | MBA Inteli, Módulo 3 | apresentação em 09/10/2026
Grupo 2: Allan Oliveira, Guilherme Souza, Ivan Hasse e Stenio Souza

## Links

| Item | Onde |
|---|---|
| Repositório | https://github.com/steniosouza97-svg/clube-guardioes-mvp |
| Página de adesão (MVP no ar) | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ (Guardião, doação única e link **Minha Área** no topo) |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html (acesso restrito a voluntários cadastrados) |
| Vídeo demonstrativo | **Pendente.** Inserir o link aqui e no README depois da gravação |

## Como o MVP atende ao enunciado

| Exigência | Evidência |
|---|---|
| Executa o fluxo principal | Escolha entre Guardião de R$ 85/mês e doação única de qualquer valor, cadastro, Pix, confirmação e "Indique um novo Doador" → cobrança mensal → Pix pago ou vencido → régua de relacionamento → painel com alerta de churn. Minha Área do Guardião com status, estrelas, impacto, histórico, pausa, cancelamento, reativação e recibo anual |
| Implementa o modelo de dados | Tabelas com restrições, chave do CPF em esquema privado, views de métricas e funções como única porta de escrita. [Modelo de dados](docs/modelo_de_dados.md) e [desenho do banco em PDF](docs/diagramas/diagrama_banco_de_dados.pdf) |
| Populado com dados sintéticos | 305 Guardiões (271 ativos, 4 pausados), 2.222 cobranças e 48 doações únicas, 12 meses de operação simulada, calibrados com o business case (teste T19). Nenhum dado real (T20) |
| Passou por fase de teste | 39 testes de fluxo e 13 de acesso (local e Supabase), 25 passos de interface, 2 controles negativos e as telas principais conferidas em celular, tablet e computador ([telas em três tamanhos](docs/diagramas/telas_responsivas.png)). [Casos de teste](docs/casos_de_teste.md) |
| Validado com usuário real | Teste ao vivo com o professor Bryan (Inteli), de fora do projeto: concluiu a adesão como Guardião e a doação única. Os dados reais foram apagados pela regra de dados sintéticos, e o teste gerou a trava de e-mail da demonstração. [Teste com usuários](docs/teste_com_usuarios.md) |
| Opera de forma estável | No ar no Supabase e no GitHub Pages; testes repetíveis sem alterar dados |

**Para testar a Minha Área:** página pública, **Minha Área** no topo, **Entrar como Guardião de demonstração** (Guardião sintético Carlos Barbosa: Guardião Prata, 4 estrelas e 11 meses, a 1 estrela do Ouro).

**Para testar a adesão:** deixe o e-mail em branco ou use um terminado em `@example.com`, e um CPF fictício, como `900.000.001-75`. Nenhum valor é cobrado.

## Documentação de passagem

| Documento | Conteúdo |
|---|---|
| [README](README.md) | Instalação, acesso, testes, publicação, operação depois da semana 10 e passagem ao Instituto |
| [Rastreabilidade semana 5 → 10](docs/rastreabilidade_semana5.md) | Cada tela do protótipo da semana 5 e onde está no MVP |
| [User stories](docs/user_stories.md) | User stories com critérios de aceite ligados aos testes |
| [Modelo de dados](docs/modelo_de_dados.md) e [desenho do banco](docs/diagramas/diagrama_banco_de_dados.pdf) | Tabelas, relações, views, permissões e dicionário de dados |
| [Decisões técnicas](docs/decisoes_tecnicas.md) | Decisões numeradas, com alternativas descartadas e consequências |
| [Casos de teste](docs/casos_de_teste.md) | Cenários, resultados e defeitos encontrados |
| [Teste com usuários](docs/teste_com_usuarios.md) | Hipóteses, participantes, condução e aprendizados |
| [Privacidade e LGPD](docs/lgpd_pendencias.md) | O que o MVP garante e as pendências para operar com doadores reais |
| [Roteiro do vídeo](docs/roteiro_video.md) | Cenas, tempos e falas |
| [Como manter o MVP](CONTRIBUTING.md) | Regras para alterar o código e o banco com segurança |

## Nota para a banca

Durante o teste com usuário real (professor Bryan, Inteli), entraram na base de demonstração dois cadastros com e-mail real. O teste de integridade T20 detectou o caso; os registros foram apagados e, desde então, a demonstração só aceita e-mail terminado em `@example.com` ou em branco (teste T39; DT-19).
