{{config(materialized='view')}}


SELECT 
    id,
    id_processo,
    status,
    CASE
        WHEN data_limite ~ '^\d{4}-\d{2}-\d{2}$'
            AND (split_part(data_limite, '-', 2)::int BETWEEN 1 AND 12)  -- Valida mês
            AND (split_part(data_limite, '-', 3)::int BETWEEN 1 AND       -- Valida dia com base no mês
                CASE split_part(data_limite, '-', 2)::int
                    WHEN 1 THEN 31
                    WHEN 2 THEN 
                        CASE 
                            WHEN (split_part(data_limite, '-', 1)::int % 4 = 0 
                                  AND (split_part(data_limite, '-', 1)::int % 100 != 0 
                                       OR split_part(data_limite, '-', 1)::int % 400 = 0)) 
                            THEN 29  -- Ano bissexto
                            ELSE 28
                        END
                    WHEN 3 THEN 31
                    WHEN 4 THEN 30
                    WHEN 5 THEN 31
                    WHEN 6 THEN 30
                    WHEN 7 THEN 31
                    WHEN 8 THEN 31
                    WHEN 9 THEN 30
                    WHEN 10 THEN 31
                    WHEN 11 THEN 30
                    WHEN 12 THEN 31
                    ELSE 0  -- Mês inválido (não deve ocorrer por causa da checagem anterior)
                END)
        THEN data_limite::DATE
        ELSE NULL
    END AS data_limite, 
    LOWER(observacoes) AS observacoes,
    id_usuario,
    id_andamento,
    situacao_evento,
    data
FROM {{source('raw_producao', 'tb_processos_eventos')}}
