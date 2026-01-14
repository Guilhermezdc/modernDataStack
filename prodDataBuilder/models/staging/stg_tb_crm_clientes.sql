{{config(materialized='view')}}


WITH tb_crm_clientes AS (

    SELECT
        c.id,
        UPPER(c.nome) AS nome,
        (ARRAY['M', 'F'])[c.sexo + 1] AS sexo,
        c.data_nascimento::DATE as data_nascimento,
        c.cpf,
        c.cnpj,
        c.cep AS cep,
        c.cidade,
        c.bairro,
        c.endereco,
        UPPER(uf) AS uf,
        c.numero,
        c.telefone1,
        UPPER(c.email) AS email,
        c.id_clientes_status,
        c.id_clientes_etapas,
        c.id_origem,
        c.id_usuario,
        c.id_resultado_lead,
        "creatAt"::TIMESTAMP AS creatAt,
        "updateAt"::TIMESTAMP AS updateAt,
        "updateResultadoAt"::TIMESTAMP AS updateResultadoAt,
        c.id_rds
    FROM {{source('raw_producao', 'tb_crm_clientes')}} c

)

SELECT * FROM tb_crm_clientes