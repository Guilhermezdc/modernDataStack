{{config(materialized='view')}}

with tabela_fipe AS (
SELECT
    (retorno::json #>> '{placa}') AS placa,
    (retorno::json #>> '{informacoes_veiculo,marca}') AS marca,
    (retorno::json #>> '{informacoes_veiculo,modelo}') AS modelo,
    (retorno::json #>> '{fipe,0,valor}')::decimal AS valor,
    (retorno::json #>> '{informacoes_veiculo,ano_modelo}') AS anoModelo,
    (retorno::json #>> '{informacoes_veiculo,uf}') AS uf,
    (retorno::json #>> '{informacoes_veiculo,segmento}') AS chassi,
    (retorno::json #>> '{informacoes_veiculo,municipio}') AS renavam,
    (retorno::json #>> '{informacoes_veiculo,sub_segmento}') AS sub_segmento
FROM {{source('raw_producao', 'tb_response_api_fipe')}}
WHERE (retorno::json #>> '{placa}') IS NOT NULL
)

SELECT * FROM tabela_fipe