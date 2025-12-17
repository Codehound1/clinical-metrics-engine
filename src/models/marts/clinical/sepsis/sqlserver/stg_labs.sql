/* stg_labs.sql (Postgres)
   Grain: 1 row per lab result
   SOURCE:
     - uh.lab_result
   Notes:
     - Prefer result_ts for “when resulted”, collected_ts for “when drawn”
*/WITH src AS (
  SELECT    l.encounter_id,
    l.patient_id,
    l.lab_result_id,
    l.test_code,                 -- standardized (LOINC recommended)    l.test_name,
    l.collected_ts,
    l.result_ts,
    l.result_value_num,
    l.result_value_text,
    l.result_unit,
    l.abnormal_flag
  FROM uh.lab_result l
)SELECT * FROM src;
