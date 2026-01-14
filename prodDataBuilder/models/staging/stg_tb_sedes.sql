{{ config(materialized='view') }}

SELECT
    s.id,
    UPPER(s.sede) AS sede,
    s.cnpj,
    s.id_sede_status,
    s.cep,
    s.data_inicio_contrato::DATE,
    s.data_fim_contrato::DATE,
    s.data_inicio_operacao::DATE,
    s.data_fim_operacao::DATE,
    s.operador,
    s.is_view_bolsa,
    s.id_modelo,
    s.data_mudanca_modelo
FROM {{source('raw_producao', 'tb_sedes')}} s