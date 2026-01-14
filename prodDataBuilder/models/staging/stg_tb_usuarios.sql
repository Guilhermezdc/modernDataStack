{{config(materialized='view')}}


WITH tb_usuarios AS (
    SELECT 
        s.id,
        lower(s.nome) AS nome,
        s.cpf,
        s.data_nascimento::DATE AS data_nascimento,
        s.celular,
        s.id_grupo,
        lower(s.email) AS email,
        lower(s.email_pessoal) AS email_pessoal,
        s.login,
        s.foto,
        s.status::BOOLEAN AS status,
        s.data_desativado::DATE,
        s.data_login::TIMESTAMP,
        f.id_padrao,
        f.id_sede

    FROM {{source('raw_producao', 'tb_usuarios')}} s 
        INNER JOIN {{source('raw_producao', 'tb_funcao')}} f ON f.id = s.id_grupo
)

SELECT * FROM tb_usuarios
