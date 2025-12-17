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
expired AS (
  SELECT DISTINCT encounter_id
  FROM uh.encounter
  WHERE disposition ILIKE '%expired%')
SELECT  b.encounter_id,
  b.patient_id,
  CASE WHEN cc.encounter_id IS NOT NULL THEN 1 ELSE 0 END AS is_comfort_care,
  CASE WHEN hs.encounter_id IS NOT NULL THEN 1 ELSE 0 END AS is_hospice,
  CASE WHEN ex.encounter_id IS NOT NULL THEN 1 ELSE 0 END AS is_expired,
  CASEWHEN cc.encounter_id IS NOT NULL THEN 'Comfort care'WHEN hs.encounter_id IS NOT NULL THEN 'Hospice'WHEN ex.encounter_id IS NOT NULL THEN 'Expired'ELSE NULLEND AS exception_reason
FROM base bLEFT JOIN comfort_care cc ON cc.encounter_id = b.encounter_idLEFT JOIN hospice hs      ON hs.encounter_id = b.encounter_idLEFT JOIN expired ex      ON ex.encounter_id = b.encounter_id;
