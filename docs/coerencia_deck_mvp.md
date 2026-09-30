# Conferência cruzada: deck × MVP × modelo financeiro

Clube Guardiões do Futuro | tarefa CJ1 | realizada em 28/09/2026, revista em 29/09/2026 após as decisões de 29/09 e fechada em 30/09/2026 com o deck `Pitch_Deck_Clube_Guardioes_final_30-09` (plano em fases, slide novo "O que o Instituto ganha" e Pedido separado) e a planilha `Modelo_Financeiro_Clube_Guardioes_final_30-09`

As duas trilhas contam a mesma história com os mesmos números. Esta conferência compara cada afirmação do pitch deck que depende do MVP ou do modelo financeiro com o que o repositório e a planilha efetivamente fazem.

## Resultado

| Slide | Afirmação no deck | Onde se confere | Situação |
|---|---|---|---|
| 2 | A Asaas, já contratada, é a base da solução | DT-01; `parametro.custo_pix` | Coerente |
| 4 | 35 Guardiões ativos a R$ 80/mês | Planilha, Premissas H11; gerador parte de 35 da "Base Pix manual" | Coerente: a base atual mantém o valor que já doa; R$ 85 vale para novas adesões e reativações |
| 4 | 40 doadores pontuais prontos para conversão | Planilha: 30 conversões no plano em fases, 5 por mês na Fase 1 (8 a 25 nos cenários de sensibilidade) | Coerente: o deck fala do estoque de 40; a planilha converte 75% dele no plano |
| 5 | Passo 1, Adesão com Pix recorrente | `fn_aderir_publico`, `fn_gerar_cobrancas`; T01, T05, T16 | Coerente |
| 5 | Doação única de qualquer valor, para quem não pode ser mensal | `fn_doar_unica`, aba Doações únicas; T33, S13, E22, E24 | Coerente: slide 5, Passo 1 e "No escopo do MVP" |
| 5 | Pausa de 1 a 3 meses em vez de cancelar | `fn_pausar`, `fn_retomar`, `fn_area_acao`; T34, T36, E23, E24 | Coerente: slide 5, Passo 4 |
| 5 | Minha Área do Guardião (status, impacto, histórico, pausar, cancelar, reativar) | `fn_area`, `fn_area_acao`; T35, T36, E23 | Coerente: slide 5, Passo 3 e "No escopo do MVP" |
| 5 | Indique um novo Doador pelo WhatsApp, com link pessoal | `codigo_convite`, `convite_usado`, `fn_convite_nome`; T29, T33, S12, E19, E22 | Coerente: slide 5, Passo 2 |
| 5 | Estrelas e níveis (Bronze, Prata, Ouro) | `fn_nivel`, `parametro.meses_por_estrela` = 3; T37, E23 | Coerente: slide 5, Passo 3 e nota de fala (1ª estrela na primeira doação, Ouro em 12 meses) |
| 5 | Passo 2, Agradecimento automático | `fn_processar_evento` (PAYMENT_RECEIVED); T06, T07 | Coerente |
| 5 | Passo 3, Conteúdo mensal de impacto | `fn_enviar_impacto_mensal`; T13 | Coerente |
| 5 | Passo 4, Régua e recuperação de cobrança | Lembrete, alerta de churn, recuperação; T08, T09, T10 | Coerente |
| 5 | Painel interno com alerta de churn | `vw_alerta_churn`, aba Alerta de churn; E10 | Coerente |
| 5 | Não promete dedução de IR | Página de adesão; CONTRIBUTING.md | Coerente |
| 6 | MVP no ar, testes aprovados, CPF cifrado | 39 de fluxo + 13 de acesso + 25 passos de interface (E2E); DT-14; `evidencias/testes_supabase_2026-09-29_trava_demonstracao.log`, `evidencias/e2e/resultado_e2e.log` | Coerente: slide 6 diz "52 testes de regra e acesso, 25 de interface" (39 + 13) |
| 7 | R$ 3,09 por Guardião ao mês | `parametro`: R$ 1,99 Pix + 2 × R$ 0,55; planilha Premissas H20 | Coerente |
| 7 | Banco e hospedagem sem custo | Supabase e GitHub Pages em planos gratuitos; rotina anti-pausa | Coerente |
| 7 | Recibo anual emitido pelo próprio Guardião, sem promessa de dedução de IR | `fn_area_recibo`; T38, E23 | Coerente: slide 7, linha "Recibo anual ao doador", sem custo |
| 8 | Plano em fases: ROI 414,5%, VPL R$ 337 mil, payback 11 meses, 295% do custeio; ponto de equilíbrio 3,75 novos por mês | Planilha `final_30-09`, aba Resultado C14, C15, C19, C42; Cenários F23 | Coerente (recalculada em 30/09, zero erros de fórmula) |
| 8 | Indicador de cobertura do custeio de 2025 | Painel usa `parametro.custeio_anual_2025` = R$ 146.668,38 (DRE assinado) | Coerente |
| 9 | O que o Instituto ganha: 35 para 431 Guardiões, R$ 36 mil/mês em 2030, métrica novos = horas × produtividade | Planilha, Modelo Mensal colunas F e U a Z; painel mede novos, churn e canal por mês (Resumo, Canais) | Coerente |
| 11 | Churn como alavanca e VPL sob estresse | Planilha (testes de estresse de 30/09); dados sintéticos calibrados com churn perto de 2% (T19) | Coerente |
| 10 | 80 h/mês (56 h captação, 24 h retenção) nas Fases 1 e 2; 120 h (72 h e 48 h) na Fase 3 | README, "Operação depois da semana 10" | Coerente |
| 10 | Leitura do painel como competência, sem programação | README; painel sem SQL para a operação diária | Coerente |
| 10 | Gatilhos: churn acima de 4% ao mês e base abaixo de 130 no mês 12 | Resumo do painel mostra churn mensal; CSV exportável | Coerente: acompanhamento manual, sem alerta automático do gatilho |
| 11 | Guardião R$ 85; doação única de qualquer valor | `parametro.valor_guardiao` = 85; página: "Guardião R$ 85/mês (recomendado)" ou "Doação única, qualquer valor" (referências R$ 30, R$ 60, R$ 120 ou outro; mínimo técnico R$ 10); T16, T33 | Coerente: slide 11 e planilha (Cenários G11) dizem "Guardião a R$ 85; doação única de qualquer valor" |
| 11 | Processo documentado, régua automática e segundo voluntário na Fase 3 | README (manual de operação), `docs/execucao_final.md` | Coerente |

## Divergências tratadas

1. **Valores (slide 12).** Até 28/09 a página oferecia faixas a partir de R$ 50 com valor livre. Pela decisão de 29/09, o Guardião doa R$ 85 por mês (T16 recusa R$ 60 para Guardião) e qualquer valor vai para a doação única, com mínimo técnico de R$ 10. O slide e a planilha foram ajustados para "Guardião a R$ 85; doação única de qualquer valor". A doação única atende a persona que doa entre R$ 20 e R$ 100 (slide 4) sem diluir o ticket recorrente. O risco "ticket baixo contra taxa" do deck passa a valer só para doações únicas pequenas, que pagam a tarifa do Pix uma vez, e não todo mês.
4. **Slides 5, 6 e 7 depois de 29/09.** O MVP ganhou doação única, pausa, Minha Área, indicação, estrelas e recibo, e a contagem de testes mudou. Os ajustes foram aplicados no deck em 29/09 e conferidos em 30/09; não há pendência de coerência entre deck, planilha e MVP.
2. **Texto da planilha sobre plataformas.** A aba Plataformas recomendava negociar com a Doare. Atualizada para a decisão final (Asaas); o comparativo ficou como evidência de apoio.
3. **Custo da Asaas no Leia-me da planilha.** Dizia "ainda não informado". Atualizado para R$ 3,09 por Guardião ao mês, pela tabela pública.
5. **Planilha depois de 29/09 (revisão de 30/09).** A planilha ainda trazia o nome antigo do Clube, "faixas a partir de R$ 50", recibo a R$ 0,49 e operação de 3 h/semana. A versão `final_30-09` corrige esses textos e registra que doação única, pausa, estrelas e indicação não estão embutidas nas premissas; nenhum número mudou.

6. **Plano de captação em fases (30/09).** O plano previa 20 novos Guardiões por mês desde o primeiro mês (548 no mês 36). Passou a uma curva em três fases (5 a 10, 12 a 15 e 18 por mês; 80 h, 80 h e 120 h), com 431 Guardiões no mês 36. Deck, planilha, README e T19 foram alinhados. A base de demonstração do MVP continua com o volume anterior (275 Guardiões no mês 12), acima do plano de propósito, para testar o painel com mais carga.

## Regra para daqui em diante

Qualquer mudança de premissa na planilha que afete ticket, churn ou aquisição exige conferir o gerador de dados sintéticos (`db/05_dados_sinteticos.sql`) e o teste de calibração T19, e vice-versa.
