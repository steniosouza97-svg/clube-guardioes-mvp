# Conferência cruzada: deck × MVP × modelo financeiro

Clube Guardiões do Começo | tarefa CJ1 | realizada em 28/09/2026

As duas trilhas contam a mesma história com os mesmos números. Esta conferência compara cada afirmação do pitch deck que depende do MVP ou do modelo financeiro com o que o repositório e a planilha efetivamente fazem.

## Resultado

| Slide | Afirmação no deck | Onde se confere | Situação |
|---|---|---|---|
| 2 | A Asaas, já contratada, é a base da solução | DT-01; `parametro.custo_pix` | Coerente |
| 4 | 35 Guardiões ativos a R$ 80/mês | Planilha, Premissas H11; gerador parte de 35 da "Base Pix manual" | Coerente |
| 4 | 40 doadores pontuais prontos para conversão | Planilha: 30 conversões no plano Dedicado (8 a 25 nos cenários de sensibilidade) | Coerente: o deck fala do estoque de 40; a planilha converte 75% dele no plano |
| 5 | Passo 1, Adesão com Pix recorrente | `fn_aderir_publico`, `fn_gerar_cobrancas`; T01, T05, T16 | Coerente |
| 5 | Passo 2, Agradecimento automático | `fn_processar_evento` (PAYMENT_RECEIVED); T06, T07 | Coerente |
| 5 | Passo 3, Conteúdo mensal de impacto | `fn_enviar_impacto_mensal`; T13 | Coerente |
| 5 | Passo 4, Régua e recuperação de cobrança | Lembrete, alerta de churn, recuperação; T08, T09, T10 | Coerente |
| 5 | Painel interno com alerta de churn | `vw_alerta_churn`, aba Alerta de churn; E10 | Coerente |
| 5 | Não promete dedução de IR | Página de adesão; CONTRIBUTING.md | Coerente |
| 6 | MVP no ar, 39 testes aprovados, CPF cifrado | 28 de fluxo + 11 de acesso; DT-14; `evidencias/` | Coerente |
| 7 | R$ 3,09 por Guardião ao mês | `parametro`: R$ 1,99 Pix + 2 × R$ 0,55; planilha Premissas H20 | Coerente |
| 7 | Banco e hospedagem sem custo | Supabase e GitHub Pages em planos gratuitos; rotina anti-pausa | Coerente |
| 8 | ROI 899,8%, VPL R$ 615 mil, payback 4 meses, 378% do custeio | Planilha, aba Resultado C14, C15 | Coerente (recalculada em 28/09, zero erros de fórmula) |
| 8 | Indicador de cobertura do custeio de 2025 | Painel usa `parametro.custeio_anual_2025` = R$ 146.668,38 (DRE assinado) | Coerente |
| 9 | Churn como alavanca | Dados sintéticos calibrados com churn perto de 2% (T19) | Coerente |
| 11 | 80 h/mês, 56 h aquisição e 24 h retenção | README, "Operação depois da semana 10" | Coerente |
| 11 | Leitura do painel como competência, sem programação | README; painel sem SQL para a operação diária | Coerente |
| 11 | Gatilho: churn acima de 4% ao mês | Resumo do painel mostra churn mensal; CSV exportável | Coerente: acompanhamento manual, sem alerta automático do gatilho |
| 12 | Faixas a partir de R$ 50 | Página: R$ 50, R$ 80, R$ 95 ou outro valor | **Ajustado:** a página dizia "a partir de R$ 50" mas aceitava valor livre desde R$ 10. O texto passou a listar as faixas e o valor livre |
| 12 | Processo documentado e substituto treinado | README (manual de operação), `docs/execucao_final.md` | Coerente |

## Divergências tratadas

1. **Texto da página de adesão (slide 12).** Corrigido em `web/index.html`. O limite técnico de R$ 10 continua: o valor livre atende a persona que doa entre R$ 20 e R$ 100 (slide 4). Com R$ 3,09 de custo fixo, uma doação de R$ 20 retém 15%; o deck já trata esse ponto como risco "ticket baixo contra taxa".
2. **Texto da planilha sobre plataformas.** A aba Plataformas recomendava negociar com a Doare. Atualizada para a decisão final (Asaas); o comparativo ficou como evidência de apoio.
3. **Custo da Asaas no Leia-me da planilha.** Dizia "ainda não informado". Atualizado para R$ 3,09 por Guardião ao mês, pela tabela pública.

## Regra para daqui em diante

Qualquer mudança de premissa na planilha que afete ticket, churn ou aquisição exige conferir o gerador de dados sintéticos (`db/05_dados_sinteticos.sql`) e o teste de calibração T19, e vice-versa.
