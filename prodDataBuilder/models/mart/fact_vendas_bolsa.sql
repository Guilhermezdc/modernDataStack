{{ config(materialized='table') }}

WITH vendasBolsa AS (
    SELECT
        crm.id_crm_cliente,
        crm.id_rds,
        fv.id_sede AS sede_venda,
        CASE
            WHEN l.id_sede = 1 AND fv.id_sede IN (85, 54) THEN fv.id_sede
            ELSE l.id_sede
        END AS sede_arremate,
        l.data_arremate,
        l.id_lances,
        fv.id_processo,
        fv.data_compra,
        c.id AS id_cliente,
        fv.valor,
        crm.telefone1
    FROM {{ ref("fact_leads_leiloados") }} l
    INNER JOIN {{ ref('dim_crm_leads') }} crm
        ON crm.id_crm_cliente = l.id_crm
    INNER JOIN {{ ref('fact_crm_leads') }} fcrm
        ON fcrm.id_crm_cliente = crm.id_crm_cliente
    INNER JOIN {{ ref('stg_tb_clientes') }} c
        ON c.id_crm = crm.id_crm_cliente
    INNER JOIN {{ ref('fact_vendas') }} fv
        ON c.id = fv.id_cliente
    WHERE fv.data_compra >= l.data_entrada
      AND fv.data_compra < l.data_entrada + INTERVAL '75 days'
),

vendasBolsa_unicas AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY id_processo ORDER BY data_compra ASC) AS rn
    FROM vendasBolsa
)

SELECT
    id_processo,
    id_cliente,
    data_arremate,
    data_compra,
    id_lances,
    sede_venda,
    sede_arremate,
    valor,
    telefone1
FROM vendasBolsa_unicas
WHERE rn = 1