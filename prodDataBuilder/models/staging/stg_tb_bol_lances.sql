{{config(materialized='view')}}

WITH tb_bol_lances AS (

    SELECT
        id,
        valor AS valor_base,
        timeout::TIMESTAMP AS data_entrada,
        UPPER(cidade) AS cidade,
        UPPER(nome_cliente) AS nome_cliente,
        UPPER(estado) AS uf,
        LOWER(ci_autuacao) AS tag,
        id_crm,
        id_lance_grupo
    FROM {{source('raw_bolsa', 'tb_bol_lances')}} 

)

SELECT * FROM tb_bol_lances