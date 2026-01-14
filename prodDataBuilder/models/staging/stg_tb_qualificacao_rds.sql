{{config(materialized='view')}}

WITH tb_qualificacao_rds AS (
    SELECT
        rd.id,
        rd.id_rds,
        rd.id_origem,
        rd.id_regra,
        rd.tag_bolsa,
        rd.sede_alvo,
        rd.valor_lance_inicial,
        rd.data_criacao::TIMESTAMP AS data_criacao,
        rd.body::JSON AS body,
        (rd.body::json #>> '{leads,0,tags}') AS tag_rdStation,
        (rd.body::json #>> '{leads,0,last_conversion,source}') AS utm_source,
        (rd.body::json #>> '{leads,0,last_conversion,content,identificador}') AS identificador,
        (rd.body::json #>> '{leads,0,last_conversion,content,event_identifier}') AS event_identifier,
        (rd.body::json #>> '{leads,0,last_conversion,content,traffic_source}') AS traffic_source,
        (rd.body::json #>> '{leads,0,last_conversion,content,__cdp__original_event,payload,conversion_identifier}') AS utm_camping,
        (rd.body::json #>> '{leads,0,last_conversion,content,__cdp__original_event,payload,traffic_campaign}') AS traffic_campaign,
        rd.observacoes,
        rd.acao_final_formulario
    FROM {{source('raw_producao', 'tb_qualificacao_rds')}} rd

)

SELECT * FROM tb_qualificacao_rds