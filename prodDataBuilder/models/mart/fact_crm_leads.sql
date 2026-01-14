{{
  config(
    materialized = 'table',
    unique_key = 'chave_unica',
    on_schema_change = 'sync_all_columns'
  )
}}

{% set relevant_actions = [3,4,8,9,15,22] %}

WITH fonte_logs AS (
    SELECT
        id_crm_cliente,
        id_acao,
        descricao_acao,
        data::TIMESTAMP AS data_log
    FROM {{ ref('stg_tb_crm_log_clientes') }}
    WHERE id_acao IN ( {{ relevant_actions|join(', ') }} )
),

passagens AS (
    SELECT
        l.id_crm_cliente,
        l.id_acao AS id_acao_entrada,
        l.descricao_acao AS acao_entrada,
        l.data_log AS data_entrada,

        LEAD(l.data_log) OVER (
            PARTITION BY l.id_crm_cliente
            ORDER BY l.data_log
        ) AS proxima_data_qualquer,

        MIN(
            CASE WHEN s.id_acao IN (4,8,22) THEN s.data_log END
        ) OVER (
            PARTITION BY l.id_crm_cliente
            ORDER BY l.data_log
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) AS data_saida_raw,

        MIN(
            CASE
                WHEN s.id_acao = 4 THEN 'Perdido'
                WHEN s.id_acao = 8 THEN 'Conquistado'
                WHEN s.id_acao = 22 THEN 'Contestado'
            END
        ) OVER (
            PARTITION BY l.id_crm_cliente
            ORDER BY l.data_log
            ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING
        ) AS status_raw

    FROM fonte_logs l
    LEFT JOIN fonte_logs s
      ON s.id_crm_cliente = l.id_crm_cliente
     AND s.data_log > l.data_log
     AND s.id_acao IN (4,8,22)
    WHERE l.id_acao IN (9, 3, 15)
)

SELECT
    id_crm_cliente,
    acao_entrada,
    data_entrada,

    COALESCE(data_saida_raw, proxima_data_qualquer) AS data_saida,

    ROW_NUMBER() OVER (
        PARTITION BY id_crm_cliente
        ORDER BY data_entrada
    ) AS ordem_passagem,

    COALESCE(status_raw, 'Aberto') AS status,

    (id_crm_cliente::TEXT ||
     ROW_NUMBER() OVER (
        PARTITION BY id_crm_cliente
        ORDER BY data_entrada
     )::TEXT
    ) AS chave_unica

FROM passagens
WHERE data_entrada IS NOT NULL
