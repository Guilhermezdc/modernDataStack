{{ config(materialized='view') }}

WITH crm_id AS (
    SELECT 
        cr.id,
        cr.telefone1 
    FROM {{ source('raw_producao', 'tb_crm_clientes') }} cr
)

SELECT 
    c.id,
    TRIM(UPPER(c.nome)) AS nome,
    TRIM(UPPER(c.tipo_pessoa)) AS tipo_pessoa,
    (ARRAY['M', 'F'])[c.sexo + 1] AS sexo,
    c.permissionado AS permissionario,
    c.cpf,
    c.cnpj,
    UPPER(c.rg) AS rg,
    CASE 
        WHEN c.cnh ~ '^-?[0-9]+$' THEN c.cnh
        ELSE NULL
    END AS cnh,
    c.iduf_cnh,
    DATE(c.primeira_habilitacao) AS primeira_habilitacao,
    DATE(c.nascimento) AS nascimento,
    c.profissao,
    c.estado_civil,
    CASE 
        WHEN c.cep ~ '^-?[0-9]+$' THEN c.cep::int
        ELSE NULL
    END AS cep,
    c.cidade,
    c.bairro,
    UPPER(c.endereco) AS endereco,
    UPPER(c.complemento) AS complemento,
    UPPER(c.uf) AS uf,
    LOWER(c.numero) AS numero,
    c.telefone1 AS telefone1,
    c.telefone2 AS telefone2,
    LOWER(c.email) AS email,
    UPPER(c.como_conheceu) AS como_conheceu,
    c.id_sede,
    c.data_cadastro AS data_cadastro,
    c.status_termo AS status_termo,
    c.contador AS contador,
    c.validado AS validado,
    c.emailvalidado AS emailvalidado,
    crm_id.id AS id_crm

FROM {{ source('raw_producao', 'tb_clientes') }} c
INNER JOIN crm_id 
    ON crm_id.telefone1 = c.telefone1
