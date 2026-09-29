# Entrega da semana 10: trilha de Tecnologia

Clube Guardiões do Começo | Instituto de Cultura e Lazer Ebenézer | MBA Inteli, Módulo 3 | apresentação em 09/10/2026

## Links

| Item | Onde |
|---|---|
| Repositório | https://github.com/steniosouza97-svg/clube-guardioes-mvp |
| Página de adesão (MVP no ar) | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html (acesso restrito a voluntários cadastrados) |
| Vídeo demonstrativo | **Pendente (T7).** Inserir o link aqui e no README depois da gravação |

## Como o MVP atende ao enunciado

| Exigência | Evidência |
|---|---|
| Executa o fluxo principal | Jornada da semana 5 (cadastro, Pix, confirmação, convite) → cobrança mensal → Pix pago ou vencido → régua de relacionamento → painel com alerta de churn. Ver README e [conferência deck × MVP](docs/coerencia_deck_mvp.md) |
| Implementa o modelo de dados | 10 tabelas com restrições (mais a chave do CPF em esquema privado), 6 views de métricas e funções como única porta de escrita. [Modelo de dados](docs/modelo_de_dados.md) |
| Populado com dados sintéticos | 305 Guardiões, 12 meses de operação simulada, calibrados com o business case (teste T19). Nenhum dado real (T20) |
| Passou por fase de teste | 31 testes de fluxo e 12 de acesso, 22 passos de interface e 2 controles negativos. [Casos de teste](docs/casos_de_teste.md) e `evidencias/` |
| Opera de forma estável | No ar desde 28/09 no Supabase e no GitHub Pages; rotina que impede a pausa do plano gratuito; testes repetíveis sem alterar dados |

## Documentação de handover

| Documento | Conteúdo |
|---|---|
| [Rastreabilidade semana 5 → 10](docs/rastreabilidade_semana5.md) | Cada tela do protótipo da semana 5 e onde está no MVP, com o que ficou para a fase 2 e por quê |
| [README](README.md) | Instalação, acesso, testes, publicação, operação depois da semana 10, passagem ao Instituto |
| [Modelo de dados](docs/modelo_de_dados.md) | Tabelas, relações, views e regras de integridade |
| [Decisões técnicas](docs/decisoes_tecnicas.md) | DT-01 a DT-16, com alternativas descartadas e consequências |
| [Casos de teste](docs/casos_de_teste.md) | Cenários, resultados e defeitos encontrados |
| [User stories](docs/user_stories.md) | US01 a US10 com critérios de aceite ligados aos testes |
| [Privacidade e LGPD](docs/lgpd_pendencias.md) | O que o MVP garante e as pendências L1 a L10, com dono e prazo |
| [Roteiro do vídeo](docs/roteiro_video.md) | Cenas, tempos e falas |
| [Execução final](docs/execucao_final.md) | Checklist da véspera |
| [Regra de congelamento](CONTRIBUTING.md) | O que pode mudar entre 03/10 e 09/10 |

## Situação em 28/09/2026

Tudo concluído, exceto o vídeo demonstrativo (T7) e a execução da véspera (08/10), que é agendada por natureza.
