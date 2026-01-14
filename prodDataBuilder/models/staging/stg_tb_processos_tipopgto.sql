{{config(materialized='view')}}

WITH tb_processos_tipopgto AS (
    SELECT 
        pgt.id AS id,
        pgt.id_processo AS id_processo,
        pgt.id_cliente AS id_cliente,
        ROUND(pgt.valor::DECIMAL, 2) AS valor,
        pgt.data_inicial::DATE,
        CASE WHEN 
            pgt.id_tipopgto = 20 THEN pag.id_meiopgto
            ELSE pgt.id_tipopgto END AS id_tipopgto,
        CASE WHEN 
            pgt.id_tipopgto = 20 THEN pag.parcelas
            ELSE pgt.parcelas END AS parcelas
    FROM {{source('raw_producao', 'tb_processos_tipopgto')}} pgt
        LEFT JOIN {{ref("stg_tb_processos_agrupados")}}  pag ON pgt.id_processo = pag.id_processo
)

SELECT * FROM tb_processos_tipopgto