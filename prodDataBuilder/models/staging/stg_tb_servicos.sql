{{config(materialized='view')}}

WITH tb_servicos AS (

    SELECT
        s.id,
        s.descricao,
        id_cat_servico,
        -- Service classification logic:
        -- AVA+ category: Premium valuation services (either category 7,9 or specific service IDs)
        --   - Categories: 7 (assessment), 9 (premium)
        --   - Service IDs: 47,48,49,51,52,53 (high-value services)
        -- AVB category: Secondary valuation services (categories 1,5,10,11,12)
        -- AVA: Standard valuation services (all other categories)
        -- Others: Catch-all for unmapped categories
        CASE
            WHEN s.id_cat_servico IN (7, 9) OR s.id IN (47, 48, 49, 51, 52, 53) THEN 'AVA+'
            WHEN s.id_cat_servico IN (1, 5, 10, 11, 12) THEN 'AVB'
            WHEN s.id_cat_servico NOT IN (1, 5, 10, 11, 12) THEN 'AVA'
            ELSE 'outros'
        END AS especificacao,
        -- Service categorization with special handling for DUI/intoxication cases
        CASE
            WHEN s.descricao LIKE '%Embriaguez%' AND ss.id = 6 THEN 'TE - Embriaguez'
            WHEN s.descricao LIKE '%Embriaguez%' AND ss.id = 8 THEN 'PA - Embriaguez'
            WHEN ss.categoria_servico is null THEN 'Outros'
            ELSE ss.categoria_servico
        END AS categorias
    FROM {{source('raw_producao', 'tb_servicos')}} s
        LEFT JOIN {{source('raw_producao', 'tb_categoria_servicos')}} ss ON ss.id = s.id_cat_servico
)

SELECT * FROM tb_servicos