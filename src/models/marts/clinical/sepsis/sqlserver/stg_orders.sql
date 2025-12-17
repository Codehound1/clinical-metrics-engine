/* stg_orders.sql (Postgres)
   Grain: 1 row per order event
   SOURCE:
     - uh.order_proc (procedures/diagnostics)
*/
 
WITH src AS (
  SELECT
    o.encounter_id,
    o.patient_id,
    o.order_id,
    o.order_ts,
    o.order_status,         -- e.g. placed/completed/cancelled
    o.order_code,           -- standardized code (LOINC/CPT/local)
    o.order_name,
    o.order_category        -- e.g. blood_culture, lactate_order, etc (recommended mapping)
  FROM uh.order_proc o
)
SELECT *
FROM src;
