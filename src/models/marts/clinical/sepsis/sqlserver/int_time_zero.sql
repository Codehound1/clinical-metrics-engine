/* int_time_zero.sql (Postgres)
   Purpose: compute Time Zero (T0) consistently.

   Practical T0 approach (vendor-neutral):
     - suspected_infection_ts = MIN(blood_culture_order_ts, first_antibiotic_ts)
     - organ_dysfunction_ts   = first lactate collected/resulted (placeholder for SOFA logic)
     - time_zero_ts           = LEAST(suspected_infection_ts, organ_dysfunction_ts)
   You can replace organ_dysfunction_ts later with SOFA/vasopressor/MAP/creatinine/etc.
*/WITH cand AS (
  SELECT * FROM marts_clinical_sepsis_postgres.int_sepsis_candidates
  WHERE is_sepsis_candidate = 1),
calc AS (
  SELECT    encounter_id,
    patient_id,

    -- suspected infection timestamp    LEAST(
      COALESCE(blood_culture_order_ts, TIMESTAMP '9999-12-31'),
      COALESCE(first_antibiotic_ts,    TIMESTAMP '9999-12-31')
    ) AS suspected_infection_ts_raw,

    -- organ dysfunction timestamp proxy (lactate draw)COALESCE(first_lactate_collected_ts, first_lactate_result_ts) AS organ_dysfunction_ts

  FROM cand
),final AS (
  SELECT    encounter_id,
    patient_id,

    CASEWHEN suspected_infection_ts_raw = TIMESTAMP '9999-12-31' THEN NULLELSE suspected_infection_ts_raw
    END AS suspected_infection_ts,

    organ_dysfunction_ts,

    CASEWHEN organ_dysfunction_ts IS NULL AND suspected_infection_ts_raw = TIMESTAMP '9999-12-31' THEN NULLWHEN organ_dysfunction_ts IS NULL THEN suspected_infection_ts_raw
      WHEN suspected_infection_ts_raw = TIMESTAMP '9999-12-31' THEN organ_dysfunction_ts
      ELSE LEAST(organ_dysfunction_ts, suspected_infection_ts_raw)
    END AS time_zero_ts
  FROM calc
)SELECT * FROM final;
