{{config(materialized='view')}}


WITH logs_service AS (
    
    SELECT
        id,
        id_crm_cliente,
        id_servico,
        id_usuario,
        qtd,
        valor,
        somatorio AS valor_total,
        status,
        datacadastro::TIMESTAMP AS data_cadastro

    FROM {{source('raw_producao', 'tb_crm_servicos_clientes')}}
)


SELECT * FROM logs_service