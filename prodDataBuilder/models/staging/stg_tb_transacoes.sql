{{config(materialized='view')}}

SELECT 
    id,
    UPPER(guid) AS guid,
    lower(plataforma) AS plataforma,
    id_processo,
    id_agrupamento,
    id_tipo_transacao,
    tipo_transacao,
    qtd_parcelas,
    valor_transacao::DECIMAL,
    valor_transacao_juros::DECIMAL,
    percentual_juros_cliente,
    id_processo_tipopgto,
    valor_franqueadora::DECIMAL,
    valor_liquido_franqueado::DECIMAL,
    data_criacao_transacao::TIMESTAMP,
    data_atualizacao::TIMESTAMP,

    status,
    id_plataforma,
    data_boleto::DATE,
    id_sede,
    id_cliente

FROM {{source('raw_producao', 'tb_transacoes')}}