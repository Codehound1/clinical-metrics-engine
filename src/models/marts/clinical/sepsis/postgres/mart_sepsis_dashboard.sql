/* mart_sepsis_dashboard.sql (Postgres)
   Purpose: dashboard-ready dataset (one row per sepsis candidate encounter)

   What it outputs:
     - core timestamps
     - bundle flags
     - completion summary
     - exception reason
*/WITH bundle AS (
  SELECT * FROM marts_clinical_sepsis_postgres.fct_sepsis_bundle
),
exc AS (
  SELECT * FROM marts_clinical_sepsis_postgres.fct_sepsis_exceptions
)
SELECT  b.encounter_id,
  b.patient_id,
  b.time_zero_ts,

  b.lactate_collected_ts,
  b.blood_culture_order_ts,
  b.first_antibiotic_ts,

  b.lactate_within_3h_of_t0,
  b.blood_culture_before_antibiotic,
  b.antibiotic_within_3h_of_t0,

  b.minutes_t0_to_antibiotic,
  b.minutes_t0_to_lactate,

  -- overall bundle completion (simple version)CASEWHEN COALESCE(e.is_comfort_care,0)=1 OR COALESCE(e.is_hospice,0)=1 OR COALESCE(e.is_expired,0)=1 THEN NULLWHEN b.lactate_within_3h_of_t0 = 1AND b.blood_culture_before_antibiotic = 1AND b.antibiotic_within_3h_of_t0 = 1THEN 1 ELSE 0END AS bundle_completed_flag,

  e.exception_reason
FROM bundle bLEFT JOIN exc e
  ON e.encounter_id = b.encounter_id;
