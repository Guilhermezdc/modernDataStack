{{ config(materialized='table') }}

WITH ultimo_andamento AS (
    SELECT 
        id_processo,
        data,
        data_limite,
        ROW_NUMBER() OVER (PARTITION BY id_processo ORDER BY data DESC) AS rn
    FROM {{ ref('stg_tb_processos_eventos')}} pe
    INNER JOIN {{ref('stg_tb_processos')}} p ON p.id = pe.id_processo
    WHERE p.status IN ('Em Andamento', 'Pendente')
)

SELECT 
    COUNT(*) AS qtd_processos_validos
FROM ultimo_andamento
WHERE rn = 1
  AND DATE(data_limite) < CURRENT_DATE
  AND data_limite IS NOT NULL
