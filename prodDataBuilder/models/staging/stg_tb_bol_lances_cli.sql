{{config(materialized='view')}}

WITH tb_bol_lances_cli AS (
    
    SELECT
        id,
        ROUND(valor_oferta::DECIMAL, 2) AS valor_oferta,
        data_oferta::TIMESTAMP AS data_oferta,
        id_usuario,
        id_lance,
        id_status
    FROM {{source('raw_bolsa', 'tb_bol_lances_cli')}}
)

SELECT * FROM tb_bol_lances_cli