{{config(materialized='view')}}

WITH origem AS (
    SELECT
        id,
        UPPER(descricao) AS descricao,
        data_cadastro::TIMESTAMP AS data_cadastro,
        status
    FROM {{source('raw_producao', 'origem')}}
)

SELECT * FROM origem