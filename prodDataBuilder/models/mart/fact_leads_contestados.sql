{{ config(materialized='table') }}


WITH leadsContestados AS (
    SELECT
        c.id         AS id_lead,
        c.nome,
        c.telefone1 AS telefone,
        s.sede       AS unidade,
        s.id         AS id_sede,
        u.nome       AS funcionario,
        u.id         AS id_funcionario,
        r.resultado  AS motivo,
        TO_CHAR(lc1.data, 'DD/MM/YYYY') AS data_contestacao,
        TO_CHAR(lc3.data, 'DD/MM/YYYY') AS data_arremate,
        lc1.id       AS lc1_id
    FROM {{ref('stg_tb_crm_clientes')}} c
             JOIN {{ ref('stg_tb_usuarios') }} u   ON u.id = c.id_usuario
             JOIN {{source('raw_producao', 'tb_funcao') }} f     ON f.id = u.id_grupo
             JOIN {{ ref('stg_tb_sedes') }} s      ON s.id = f.id_sede
             LEFT JOIN {{ source('raw_producao', 'tb_crm_resultado_lead') }} r ON r.id_resultado = c.id_resultado_lead
             JOIN {{ ref('stg_tb_crm_log_clientes') }} lc1
                  ON lc1.id_crm_cliente = c.id
                      AND lc1.acao ILIKE '%contest%'
             LEFT JOIN {{ ref('stg_tb_crm_log_clientes') }} lc2
                       ON lc2.id_crm_cliente = lc1.id_crm_cliente
                           AND lc2.acao ILIKE '%contest%'
                           AND lc2.id > lc1.id
             LEFT JOIN {{ ref('stg_tb_crm_log_clientes') }} lc3
                       ON lc3.id_crm_cliente = c.id
                           AND lc3.acao ILIKE '%Lead arrematado%'
    WHERE lc2.id IS NULL
    ORDER BY lc1.id DESC
),

-- Último "Lead arrematado" por cliente (valor final), agora seguro
     valorLeads AS (
         SELECT id_crm_cliente, valor_final
         FROM (
                  SELECT
                      la.id_crm_cliente,
                      CASE
                          WHEN position('R$' IN la.acao) > 0 THEN
                              CAST(
                                      NULLIF(
                                              replace(
                                                      regexp_replace(
                                                              substring(la.acao FROM position('R$' IN la.acao) + 2),
                                                              '[^0-9,\.]', '', 'g'
                                                      ),
                                                      ',', '.'
                                              ),
                                              ''
                                      ) AS numeric(10,2)
                              )
                          ELSE NULL
                          END AS valor_final,
                      ROW_NUMBER() OVER (PARTITION BY la.id_crm_cliente ORDER BY la.id DESC) AS rn
                  FROM {{ ref('stg_tb_crm_log_clientes') }} la
                  WHERE la.acao ILIKE 'Lead arrematado%'
                    AND la.id_crm_cliente IN (SELECT id_lead FROM leadsContestados)
              ) t
         WHERE rn = 1
     ),

-- Último status (deferi/indeferi) por cliente
     statusContestato AS (
         SELECT id_crm_cliente,
                CASE
                    WHEN lower(acao) LIKE '%indeferi%' THEN 'INDEFERIDA'
                    WHEN lower(acao) LIKE '%deferi%'   THEN 'DEFERIDA'
                    ELSE NULL
                    END AS status
         FROM (
                  SELECT
                      l.id_crm_cliente,
                      l.acao,
                      ROW_NUMBER() OVER (PARTITION BY l.id_crm_cliente ORDER BY l.id DESC) AS rn
                  FROM {{ ref('stg_tb_crm_log_clientes') }} l
                  WHERE l.id_crm_cliente IN (SELECT id_lead FROM leadsContestados)
                    AND (l.acao ILIKE '%deferi%' OR l.acao ILIKE '%indeferi%')
              ) x
         WHERE rn = 1
     )

SELECT
    lc.id_lead,
    lc.nome,
    lc.telefone,
    lc.unidade,
    lc.id_sede,
    lc.funcionario,
    lc.id_funcionario,
    lc.motivo,
    lc.data_contestacao,
    lc.data_arremate,
    v.valor_final,
    COALESCE(s.status, 'PENDENTE') AS status
FROM leadsContestados lc
         LEFT JOIN valorLeads v ON v.id_crm_cliente = lc.id_lead
         LEFT JOIN statusContestato s ON s.id_crm_cliente = lc.id_lead
ORDER BY lc.lc1_id DESC