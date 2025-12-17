/* int_sepsis_candidates.sql (Postgres)
   Purpose: identify candidate encounters for sepsis evaluation
   Candidate logic (simple & practical):
     - suspected infection signal: blood culture order OR antibiotic admin
     - plus at least one supporting signal: lactate drawn/resulted, abnormal vitals, etc.
   For now, we’ll use:
     suspected_infection = blood culture order OR antibiotic
     supporting_signal   = any lactate collected/resulted
*/WITH enc AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_encounter
),
orders AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_orders
),
labs AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_labs
),
meds AS (
  SELECT * FROM marts_clinical_sepsis_postgres.stg_meds
),

blood_culture AS (
  SELECT    encounter_id,
    MIN(order_ts) AS blood_culture_order_ts
  FROM orders
  WHERE COALESCE(order_category,'') ILIKE '%blood_culture%'OR order_code IN ('BLOOD_CULTURE')  -- TODO: replace mapping
  GROUP BY 1),
antibiotic AS (
  SELECT    encounter_id,
    MIN(admin_ts) AS first_antibiotic_ts
  FROM meds
  WHERE COALESCE(med_class,'') ILIKE '%antibiotic%'OR med_code IN ('ANTIBIOTIC')       -- TODO: replace mapping
  GROUP BY 1),
lactate AS (
  SELECT    encounter_id,
    MIN(collected_ts) AS first_lactate_collected_ts,
    MIN(result_ts)    AS first_lactate_result_ts,
    MIN(result_value_num) FILTER (WHERE result_value_num IS NOT NULL) AS first_lactate_value_any
  FROM labs
  WHERE test_code IN ('LACTATE')         -- TODO: replace LOINC/local mapping
     OR test_name ILIKE '%lactate%'GROUP BY 1)
SELECT  e.encounter_id,
  e.patient_id,
  e.encounter_type,
  e.facility_id,
  e.department_id,
  e.arrival_ts,
  e.admit_ts,
  e.discharge_ts,
  bc.blood_culture_order_ts,
  abx.first_antibiotic_ts,
  lac.first_lactate_collected_ts,
  lac.first_lactate_result_ts,
  CASEWHEN bc.encounter_id IS NOT NULL OR abx.encounter_id IS NOT NULL THEN 1 ELSE 0END AS has_suspected_infection_signal,
  CASEWHEN lac.encounter_id IS NOT NULL THEN 1 ELSE 0END AS has_lactate_signal,
  CASEWHEN (bc.encounter_id IS NOT NULL OR abx.encounter_id IS NOT NULL)
     AND  lac.encounter_id IS NOT NULLTHEN 1 ELSE 0END AS is_sepsis_candidateFROM enc eLEFT JOIN blood_culture bc ON bc.encounter_id = e.encounter_idLEFT JOIN antibiotic abx   ON abx.encounter_id = e.encounter_idLEFT JOIN lactate lac      ON lac.encounter_id = e.encounter_idWHERE e.admit_ts >= DATE '2020-01-01';   -- optional guardrail 
