# Entrega da semana 10: trilha de Tecnologia

Clube Guardiões do Futuro | Instituto de Cultura e Lazer Ebenézer | MBA Inteli, Módulo 3 | apresentação em 09/10/2026

## Links

| Item | Onde |
|---|---|
| Repositório | https://github.com/steniosouza97-svg/clube-guardioes-mvp |
| Página de adesão (MVP no ar) | https://steniosouza97-svg.github.io/clube-guardioes-mvp/ (Guardião, doação única e link **Minha Área** no topo) |
| Painel do voluntário | https://steniosouza97-svg.github.io/clube-guardioes-mvp/painel.html (acesso restrito a voluntários cadastrados) |
| Vídeo demonstrativo | **Pendente (T7).** Inserir o link aqui e no README depois da gravação |

## Como o MVP atende ao enunciado

| Exigência | Evidência |
|---|---|
| Executa o fluxo principal | Jornada da semana 5 (escolha entre Guardião R$ 85/mês e doação única de qualquer valor, cadastro com e-mail opcional, Pix, confirmação, Indique um novo Doador) → cobrança mensal → Pix pago ou vencido → régua de relacionamento → painel com alerta de churn. Minha Área do Guardião (status, estrelas, impacto, histórico, pausa, cancelamento, reativação, recibo anual). Ver README e [conferência deck × MVP](docs/coerencia_deck_mvp.md) |
| Implementa o modelo de dados | Tabelas com restrições, incluindo `doacao_unica` e `tentativa_acesso` (mais a chave do CPF em esquema privado), views de métricas (com pausados e doações únicas) e funções como única porta de escrita. No Supabase, migrações aplicadas até a 31. [Modelo de dados](docs/modelo_de_dados.md) |
| Populado com dados sintéticos | 305 Guardiões (271 ativos, 4 pausados), 2.222 cobranças e 48 doações únicas, 12 meses de operação simulada, calibrados com o business case (teste T19). Nenhum dado real (T20) |
| Passou por fase de teste | 39 testes de fluxo e 13 de acesso (local e Supabase), 25 passos de interface e 2 controles negativos. [Casos de teste](docs/casos_de_teste.md); evidências em `evidencias/testes_local_2026-09-29_1404.log`, `evidencias/testes_supabase_2026-09-29_trava_demonstracao.log` e `evidencias/e2e/resultado_e2e.log` |
| Opera de forma estável | No ar desde 28/09 no Supabase e no GitHub Pages; rotina que impede a pausa do plano gratuito; testes repetíveis sem alterar dados |

**Para a banca testar a Minha Área:** página pública, **Minha Área** no topo, **Entrar como Guardião de demonstração** (Guardião sintético Carlos Barbosa, WhatsApp `(11) 90000-0040`, CPF fictício `800.000.040-73`: Guardião Prata com 4 estrelas e 11 meses, a 1 estrela do Ouro).

## Documentação de handover

| Documento | Conteúdo |
|---|---|
| [Rastreabilidade semana 5 → 10](docs/rastreabilidade_semana5.md) | Cada tela do protótipo da semana 5 (P1 e P2) e onde está no MVP |
| [README](README.md) | Instalação, acesso, testes, publicação, operação depois da semana 10, passagem ao Instituto |
| [Modelo de dados](docs/modelo_de_dados.md) | Tabelas, relações, views e regras de integridade |
| [Decisões técnicas](docs/decisoes_tecnicas.md) | Decisões DT numeradas (a partir de DT-01), com alternativas descartadas e consequências |
| [Casos de teste](docs/casos_de_teste.md) | Cenários, resultados e defeitos encontrados |
| [User stories](docs/user_stories.md) | User stories numeradas (a partir de US01) com critérios de aceite ligados aos testes |
| [Privacidade e LGPD](docs/lgpd_pendencias.md) | O que o MVP garante e as pendências L1 a L12, com dono e prazo |
| [Roteiro do vídeo](docs/roteiro_video.md) | Cenas, tempos e falas |
| [Execução final](docs/execucao_final.md) | Checklist da véspera |
| [Regra de congelamento](CONTRIBUTING.md) | O que pode mudar entre 03/10 e 09/10 |

## Nota para a banca: teste com e-mail real em 29/09/2026

Em 29/09/2026, a página publicada foi validada ao vivo com um professor da Inteli. Nesse teste entraram dois cadastros com e-mail real (um Guardião e uma doação única). O teste automático de integridade (T20), que confere se a base de demonstração só tem dados sintéticos, acusou o problema na mesma tarde.

O que foi feito:
1. Os dois registros foram apagados com autorização do grupo, junto com a mensagem de boas-vindas e as tentativas de acesso do dia. A base voltou a ter só dados sintéticos (305 Guardiões e 48 doações únicas).
2. Enquanto o parâmetro `modo_demonstracao` estiver ligado, o banco recusa e-mail que não termine em `@example.com` (ou em branco), na adesão, no cadastro pelo painel e na doação única. A página mostra o motivo antes de enviar.
3. Novo teste T39 garante a trava e confirma que, em produção (`modo_demonstracao = 0`), o e-mail comum volta a ser aceito. E01 confere a mensagem na página.

Limite que permanece: nome, WhatsApp e CPF reais não têm como ser detectados automaticamente. O aviso no topo da página pede dados fictícios, e o CPF, se informado, é guardado só como impressão digital cifrada (DT-14). Evidência: `evidencias/testes_supabase_2026-09-29_trava_demonstracao.log`.

## Situação em 29/09/2026

Decisões de 29/09 implementadas e testadas (Guardião R$ 85, doação única, pausa, Minha Área, estrelas, indicação, recibo). Tudo concluído, exceto o vídeo demonstrativo (T7) e a execução da véspera (08/10), que é agendada por natureza.
