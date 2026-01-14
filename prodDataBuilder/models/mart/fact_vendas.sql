{{ config(materialized='table') }}

WITH vendas_modelo_antigo AS (
    SELECT
        p.id,
        p.id_cliente,
        p.id_servico,
        TRIM(p.ait) AS ait,
        TRIM(UPPER(p.placa)) AS placa,
        p.uf_placa,
        p.id_orgao,
        TRIM(p.status) AS status,
        p.id_usuario_responsavel,
        p.id_usuario_cadastro,
        s.id AS id_sede_cadastro,
        TRIM(LOWER(p.observacao)) AS observacao,
        TRIM(UPPER(p.chassi)) AS chassi,
        TRIM(p.renavam) AS renavam,
        TRIM(p.numero_processamento) AS numero_processamento,
        p.id_nivel,
        p.id_multiplicador,
        p.cod_ajuda,
        p.data_cadastro AS data_cadastro,
        p.instancia,
        p.id_origem,
        p.valor_processo
    FROM {{ ref("stg_tb_processos") }} p
    INNER JOIN {{ ref("stg_tb_sedes") }} s
        ON s.id = p.id_sede_cadastro
    WHERE (s.id_modelo = 5
           OR (s.data_mudanca_modelo IS NOT NULL AND DATE(p.data_cadastro) <= s.data_mudanca_modelo))
      AND p.status NOT IN ('Cancelado', 'Cancelado Cliente')
      AND p.id_sede_cadastro != 1
),

agrupamentos_transacao AS (
    SELECT
        pa.id_processo,
        t.status,
        t.data_criacao_transacao
    FROM {{ ref('stg_tb_transacoes') }} t
    INNER JOIN {{ ref('stg_tb_processos_agrupados') }} pa
        ON pa.id = t.id_agrupamento
),

processo_unico_transacao AS (
    SELECT
        id_processo,
        status,
        data_criacao_transacao
    FROM {{ ref("stg_tb_transacoes") }}
    WHERE id_processo IS NOT NULL
      AND status = 'Pago'
),

transacao_full_raw AS (
    SELECT * FROM agrupamentos_transacao
    UNION ALL
    SELECT * FROM processo_unico_transacao
),

transacao_full AS (
    SELECT
        id_processo,
        data_criacao_transacao
    FROM (
        SELECT
            id_processo,
            data_criacao_transacao,
            ROW_NUMBER() OVER (PARTITION BY id_processo ORDER BY data_criacao_transacao ASC) AS rn
        FROM transacao_full_raw
        WHERE status = 'Pago'
    ) sub
    WHERE rn = 1
),

vendas_modelo_novo AS (
    SELECT
        p.id,
        p.id_cliente,
        p.id_servico,
        TRIM(p.ait) AS ait,
        TRIM(UPPER(p.placa)) AS placa,
        p.uf_placa,
        p.id_orgao,
        TRIM(p.status) AS status,
        p.id_usuario_responsavel,
        p.id_usuario_cadastro,
        s.id AS id_sede_cadastro,
        TRIM(LOWER(p.observacao)) AS observacao,
        TRIM(UPPER(p.chassi)) AS chassi,
        TRIM(p.renavam) AS renavam,
        TRIM(p.numero_processamento) AS numero_processamento,
        p.id_nivel,
        p.id_multiplicador,
        p.cod_ajuda,
        t.data_criacao_transacao AS data_cadastro,
        p.instancia,
        p.id_origem,
        p.valor_processo
    FROM {{ ref("stg_tb_processos") }} p
    INNER JOIN {{ ref('stg_tb_sedes') }} s
        ON s.id = p.id_sede_cadastro
    INNER JOIN transacao_full t
        ON t.id_processo = p.id
    WHERE s.id_modelo != 5
),

vendas_completo AS (
    SELECT * FROM vendas_modelo_antigo
    UNION ALL
    SELECT * FROM vendas_modelo_novo
),

vendas_unicas AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY id ORDER BY data_cadastro ASC) AS rn
    FROM vendas_completo
)

SELECT
    id AS id_processo,
    id_cliente,
    id_servico,
    id_usuario_cadastro,
    id_sede_cadastro AS id_sede,
    data_cadastro AS data_compra,
    id_origem,
    valor_processo AS valor
FROM vendas_unicas
WHERE rn = 1