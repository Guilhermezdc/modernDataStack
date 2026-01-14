{{config(materialized='view')}}

WITH niboreceipts AS (
    SELECT
        n."entryId",
        n.date::date AS date,
        n.value::numeric(19,2) AS value,
        n.category::json->>'name' AS nameCategory,
        n.reference,
        n.identifier,
        n."scheduleId",
        n.description
    FROM {{ source('raw_nibo','niboreceipts') }} n
)

SELECT * FROM niboreceipts