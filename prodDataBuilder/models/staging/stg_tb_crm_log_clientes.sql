{{config(materialized='view')}}

WITH tb_crm_log_clientes AS (
    SELECT
        l.id,
        l.id_usuario,
        l.id_cliente AS id_crm_cliente,
        l.data::TIMESTAMP AS data,
        l.acao,
        COALESCE(d.id_acao, 0) AS id_acao,
        COALESCE(d.descricao, 'Outros') AS descricao_acao
    FROM {{source('raw_producao', 'tb_crm_log_clientes')}} l
        LEFT JOIN {{ ref('dim_log_acoes') }} d
    ON lower(l.acao) LIKE lower(d.padrao_texto)
)

SELECT * FROM tb_crm_log_clientes