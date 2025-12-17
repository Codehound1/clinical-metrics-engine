* fct_sepsis_bundle.sql (Postgres)
   Purpose: bundle checks around time_zero_ts
   Bundle elements (simplified but realistic):
     - Lactate collected within 3 hours of T0
     - Blood culture ordered before first antibiotic (or within window)
     - Antibiotic within 3 hours of T0
   Later additions:
     - repeat lactate within 6h if initial > 2
     - fluids 30ml/kg if lactate >=4 or hypotension
     - vasopressors if MAP<65 after fluids
*/WITH t0 AS (
  SELECT * FROM marts_clinical_sepsis_postgres.int_time_zero
  WHERE time_zero_ts IS NOT NULL),
orders AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_orders
),
labs AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_labs
),
meds AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_meds
),
first_lactate AS (
  SELECT    l.encounter_id,
    MIN(l.collected_ts) AS lactate_collected_ts,
    MIN(l.result_ts)    AS lactate_result_ts,
    (ARRAY_AGG(l.result_value_num ORDER BY l.collected_ts NULLS LAST))[1] AS lactate_value
  FROM labs l
  WHERE l.test_code IN ('LACTATE') OR l.test_name ILIKE '%lactate%'GROUP BY 1),
blood_culture AS (
  SELECT    o.encounter_id,
    MIN(o.order_ts) AS blood_culture_order_ts
  FROM orders o
  WHERE COALESCE(o.order_category,'') ILIKE '%blood_culture%'OR o.order_code IN ('BLOOD_CULTURE')
  GROUP BY 1),
first_antibiotic AS (
  SELECT    m.encounter_id,
    MIN(m.admin_ts) AS first_antibiotic_ts
  FROM meds m
  WHERE COALESCE(m.med_class,'') ILIKE '%antibiotic%'OR m.med_code IN ('ANTIBIOTIC')
  GROUP BY 1)
SELECT  t0.encounter_id,
  t0.patient_id,
  t0.time_zero_ts,
  fl.lactate_collected_ts,
  fl.lactate_result_ts,
  fl.lactate_value,
  bc.blood_culture_order_ts,
  abx.first_antibiotic_ts,
  -- Bundle flagsCASEWHEN fl.lactate_collected_ts IS NOT NULLAND fl.lactate_collected_ts BETWEEN t0.time_zero_ts - INTERVAL '3 hours'AND t0.time_zero_ts + INTERVAL '3 hours'THEN 1 ELSE 0END AS lactate_within_3h_of_t0,
  CASEWHEN bc.blood_culture_order_ts IS NOT NULLAND abx.first_antibiotic_ts IS NOT NULLAND bc.blood_culture_order_ts <= abx.first_antibiotic_ts
    THEN 1 ELSE 0END AS blood_culture_before_antibiotic,
  CASEWHEN abx.first_antibiotic_ts IS NOT NULLAND abx.first_antibiotic_ts BETWEEN t0.time_zero_ts
                                   AND t0.time_zero_ts + INTERVAL '3 hours'THEN 1 ELSE 0END AS antibiotic_within_3h_of_t0,
  -- Useful durations (minutes)CASE WHEN abx.first_antibiotic_ts IS NULL THEN NULLELSE EXTRACT(EPOCH FROM (abx.first_antibiotic_ts - t0.time_zero_ts))/60.0END AS minutes_t0_to_antibiotic,
  CASE WHEN fl.lactate_collected_ts IS NULL THEN NULLELSE EXTRACT(EPOCH FROM (fl.lactate_collected_ts - t0.time_zero_ts))/60.0END AS minutes_t0_to_lactate
FROM t0LEFT JOIN first_lactate fl     ON fl.encounter_id = t0.encounter_idLEFT JOIN blood_culture bc     ON bc.encounter_id = t0.encounter_idLEFT JOIN first_antibiotic abx ON abx.encounter_id = t0.encounter_id;
2.8 src/models/marts/clinical/sepsis/postgres/fct_sepsis_exceptions.sql
/* fct_sepsis_exceptions.sql (Postgres)
   Purpose: exception logic for why a bundle might not apply.
   These are placeholders you can map later (comfort care, hospice, refused, expired early, transfer out).
   SOURCE:
     - uh.problem_list / uh.diagnosis / uh.patient_flags / uh.orders (as available)
*/WITH base AS (
  SELECT    encounter_id,
    patient_id
  FROM marts_clinical_sepsis_postgres.int_time_zero
  WHERE time_zero_ts IS NOT NULL),
-- Example placeholders:comfort_care AS (
  SELECT DISTINCT encounter_id
  FROM uh.patient_flags
  WHERE flag_name ILIKE '%comfort care%'),
hospice AS (
  SELECT DISTINCT encounter_id
  FROM uh.patient_flags
  WHERE flag_name ILIKE '%hospice%'),
