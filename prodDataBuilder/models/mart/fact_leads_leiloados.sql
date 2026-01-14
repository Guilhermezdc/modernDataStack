{{ config(materialized='table') }}

with lance_vencedor as (
    select
        id,
        id_lance,
        valor_oferta,
        id_usuario
    from {{ ref('stg_tb_bol_lances_cli') }}
    where id_status = 3
),

volume_lances as (
    select
        cl.id_lance,
        count(*) as total_lances
    from {{ ref('stg_tb_bol_lances_cli') }} cl
    left join lance_vencedor lv
        on cl.id_lance = lv.id_lance
    group by cl.id_lance
),

fact_leads_leiloados as (
    select
        blg.id as id_lance_grupo,
        blg.valor as valor_arremate,
        blg.timeout as data_arremate,
        blg.telefone as telefone,
        blg.tipo_lead as origem_lead,
        blg.id_status as id_status,
        blg.score as score,
        blg.id_crm_cliente as id_crm,

        bl.id as id_lances,
        bl.valor_base as valor_base,
        bl.data_entrada as data_entrada,
        bl.cidade as cidade,
        bl.nome_cliente as nome_cliente,
        bl.uf as uf,
        bl.tag as tag,

        lv.valor_oferta,
        vl.total_lances,

        coalesce(lv.id_usuario, 214) as id_usuario,
        case when lv.valor_oferta is not null then true else false end as lead_arrematado,
        case when coalesce(lv.id_usuario, 214) = 214 then 1 else u.id_sede end as id_sede

    from {{ ref('stg_tb_bol_lances_grupo') }} blg
    left join {{ ref('stg_tb_bol_lances') }} bl
        on bl.id_lance_grupo = blg.id
    left join lance_vencedor lv
        on blg.id = lv.id_lance
    left join {{ ref('stg_tb_usuarios') }} u
        on u.id = lv.id_usuario
    left join volume_lances vl
        on vl.id_lance = blg.id
)

select *
from fact_leads_leiloados
