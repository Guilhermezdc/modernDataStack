{{config(materialized='view')}}

WITH tb_orgaos AS (
    SELECT
    o.id,
    UPPER(o.descricao) AS descricao,
    UPPER(o.abreviacao) AS abreviacao,
    o.id_estado,
    o.id_tipo,
    o.status
    FROM {{source('raw_producao', 'tb_orgaos')}} o
)

SELECT * FROM tb_orgaos