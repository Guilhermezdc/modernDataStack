{{config(materialized='table')}}

WITH crm_leads AS (
    SELECT
        c.id AS id_crm_cliente,
        UPPER(c.nome) AS nome,
        c.sexo AS sexo,
        c.data_nascimento::DATE as data_nascimento,
        c.cpf::text,
        c.cnpj::text,
        c.cep AS cep,
        c.cidade,
        c.bairro,
        c.endereco,
        UPPER(c.uf) AS uf,
        c.numero,
        c.telefone1,
        UPPER(c.email) AS email,
        c.creatAt::TIMESTAMP AS creatAt,
        c.id_origem,
        c.id_rds
    FROM {{ref("stg_tb_crm_clientes")}} c
)

SELECT * FROM crm_leads