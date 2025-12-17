/* stg_encounter.sql (Postgres)
   Grain: 1 row per encounter
   SOURCE (rename to your own):
     - uh.encounter
*/
 
WITH src AS (
  SELECT
    e.encounter_id,
    e.patient_id,
    e.encounter_type,              -- ED/IP/OBS etc
    e.facility_id,
    e.department_id,
    e.admit_ts,
    e.discharge_ts,
    e.arrival_ts,
    e.disposition,                 -- discharged/admitted/transferred/expired
    e.patient_age_years,
    e.patient_weight_kg
  FROM uh.encounter e
)
SELECT *
FROM src;
