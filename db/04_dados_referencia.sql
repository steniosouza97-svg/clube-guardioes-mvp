-- =====================================================================
-- 04_dados_referencia.sql: dados reais de configuração (não sintéticos)
-- Carregar também em produção.
-- =====================================================================

insert into parametro (chave, valor, descricao) values
    ('custeio_anual_2025',      146668.38, 'Despesa total realizada em 2025, DRE assinado. Base do indicador de cobertura do custeio.'),
    ('meta_guardioes',          100,       'Meta institucional de Guardiões do Plano de Captação 2026.'),
    ('meta_recorrencia_mensal', 20000,     'Meta mensal de recorrência PF, Eixo 1 do Plano de Captação 2026.'),
    ('tentativas_ate_cancelar', 3,         'Falhas de cobrança seguidas até cancelar a assinatura por inadimplência.'),
    ('custo_pix',               1.99,      'Taxa Asaas por Pix recebido (tabela pública).'),
    ('custo_mensagem_whatsapp', 0.55,      'Taxa Asaas por mensagem WhatsApp da régua (tabela pública).');

insert into origem (nome, tipo) values
    ('Base Pix manual',             'base_existente'),
    ('Conversão de doador pontual', 'doador_pontual'),
    ('QR Code na comunidade',       'qr_code'),
    ('Instagram',                   'instagram'),
    ('WhatsApp',                    'whatsapp'),
    ('Indicação de Guardião',       'indicacao'),
    ('Campanha Dia das Crianças',   'campanha'),
    ('Campanha de Natal',           'campanha'),
    ('Site institucional',          'site');
