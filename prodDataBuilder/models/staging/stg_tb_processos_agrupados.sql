{{config(materialized='view')}}

SELECT
    id,
    id_cliente,
    unnest(string_to_array(id_processos, ','))::int AS id_processo,
    valor_total,
    id_meiopgto,
    parcelas,
    data,
    data_cadastro
FROM {{ source('raw_producao', 'tb_processos_agrupados') }}
