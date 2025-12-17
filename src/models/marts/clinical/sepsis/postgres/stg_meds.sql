/* stg_meds.sql (Postgres)
   Grain: 1 row per medication administration / start event
   SOURCE:
     - uh.med_admin (or medication_order if admin not available)
*/WITH src AS (
  SELECT    m.encounter_id,
    m.patient_id,
    m.med_event_id,
    m.med_code,                 -- RxNorm/local    m.med_name,
    m.med_class,                -- antibiotic/vasopressor/fluid etc (recommended mapping)    m.admin_ts,
    m.dose,
    m.dose_unit,
    m.route
  FROM uh.med_admin m
)SELECT * FROM src;
