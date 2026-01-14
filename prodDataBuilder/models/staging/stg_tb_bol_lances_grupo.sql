{{config(materialized='view')}}


WITH tb_bol_lances_grupo AS (
    SELECT 
        id,
        ROUND(valor::DECIMAL, 2) AS valor,
        timeout_exclusivo::TIMESTAMP AS timeout_exclusivo,
        timeout::TIMESTAMP AS timeout,
        UPPER(nome_cliente) AS nome_cliente,
        telefone,
        UPPER(uf) AS uf,
        UPPER(cidade) AS cidade,
        tipo_lead,
        id_status,
        id_crm_cliente,
        LOWER(score) AS score
    FROM {{source('raw_bolsa', 'tb_bol_lances_grupo')}}
)

SELECT * FROM tb_bol_lances_grupo