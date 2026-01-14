{{ config(materialized='view')}}

WITH valor_processo_antigoModels AS (
    SELECT
        pg.id_processo,
        SUM(pg.valor) AS valor_processo
    FROM {{ source('raw_producao', 'tb_processos_tipopgto') }} pg
    WHERE pg.id_tipopgto != 767
    GROUP BY pg.id_processo
),

valor_processo_novoModels_notGroup AS (
    SELECT
        pg.id_processo,
        SUM(pg.valor) AS valor_processo
    FROM {{ source('raw_producao', 'tb_processos_tipopgto') }} pg
        INNER JOIN {{ref("stg_tb_transacoes")}} t on t.id_processo_tipopgto = pg.id
    WHERE pg.id_tipopgto = 767
    GROUP BY pg.id_processo
),

valor_processo_novoModels_group AS (
SELECT
    id_processo,
    SUM(valor) AS valor_processo
FROM (
    SELECT DISTINCT ON (pg.id_processo)
        pg.id_processo,
        pg.valor
    FROM {{ source('raw_producao', 'tb_processos_tipopgto') }} pg
        INNER JOIN {{ ref("stg_tb_processos_agrupados") }} grp
            ON grp.id_processo = pg.id_processo
        INNER JOIN {{ ref("stg_tb_transacoes") }} t
            ON t.id_agrupamento = grp.id
    WHERE pg.id_tipopgto = 767
) dedup
GROUP BY id_processo
),

valor_processo AS (
    SELECT *
    FROM valor_processo_antigoModels
    UNION ALL
    SELECT *
    FROM valor_processo_novoModels_notGroup
    UNION ALL
    SELECT *
    FROM valor_processo_novoModels_group
),


sede AS (
    SELECT
        u.id AS id_usuario,
        f.id_sede
    FROM {{ source('raw_producao', 'tb_usuarios') }} u
    INNER JOIN {{ source('raw_producao', 'tb_funcao') }} f ON f.id = u.id_grupo
),

valor_tabela_avb AS (
    SELECT
        a.codigo,
        v.valor AS valor_tabelado
    FROM {{source('raw_producao', 'tb_perguntas') }} a
    JOIN {{source('raw_producao', 'tb_valores')}} v
        ON v.id_multiplicador = a.id_multiplicador
       AND v.id_servico = 1
       AND a.id_nivel = v.id_nivel
    GROUP BY a.codigo, v.valor
),

valor_tabela_ava AS (
    SELECT
        s.id AS id_servico,
        v.valor AS valor_tabelado
    FROM {{source('raw_producao', 'tb_servicos')}} s
    JOIN {{source('raw_producao', 'tb_valores')}} v
        ON v.id_servico = s.id
    WHERE s.id_cat_servico != 1
    GROUP BY s.id, v.valor
)

SELECT DISTINCT ON (p.id)
    p.id,
    p.id_cliente,
    p.id_servico,
    TRIM(p.ait) AS ait,
    TRIM(UPPER(p.placa)) AS placa,
    p.uf_placa,
    p.id_orgao,
    TRIM(p.status) AS status,
    p.id_usuario_responsavel,
    p.id_usuario_cadastro,
    sede.id_sede AS id_sede_cadastro,
    TRIM(LOWER(p.observacao)) AS observacao,
    TRIM(UPPER(p.chassi)) AS chassi,
    TRIM(p.renavam) AS renavam,
    TRIM(p.numero_processamento) AS numero_processamento,
    p.id_nivel,
    p.id_multiplicador,
    p.cod_ajuda,
    p.data_cadastro,
    p.instancia,
    p.id_origem,
    COALESCE(vt_avb.valor_tabelado, vt_ava.valor_tabelado) AS valor_tabelado,

    vp.valor_processo
FROM {{ source('raw_producao', 'tb_processos') }} p

INNER JOIN valor_processo vp
    ON p.id = vp.id_processo

/* 🔹 Aplica SOMENTE quando id_servico = 1 ou 2 */
LEFT JOIN valor_tabela_avb vt_avb
    ON p.id_servico IN (1, 2)
   AND vt_avb.codigo::bigint = p.cod_ajuda

/* 🔹 Aplica SOMENTE quando id_servico != 1 e != 2 */
LEFT JOIN valor_tabela_ava vt_ava
    ON p.id_servico NOT IN (1, 2)
   AND vt_ava.id_servico = p.id_servico

INNER JOIN sede
    ON sede.id_usuario = p.id_usuario_cadastro
