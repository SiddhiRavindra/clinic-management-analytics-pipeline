
-- ETL: TRANSFORM STAGING TABLES TO STAR SCHEMA
-

USE DATABASE mental_health_clinic_dw;
USE SCHEMA star_schema;

-- STEP 1: LOAD DIM_PROVIDER


INSERT INTO DIM_PROVIDER (
    provider_id,
    provider_name,
    specialty,
    effective_date,
    is_current,
    version
)
SELECT 
    provider_id,
    name AS provider_name,
    specialty,
    CURRENT_DATE() AS effective_date,
    TRUE AS is_current,
    1 AS version
FROM STG_PROVIDER;

-- Verify
SELECT 'DIM_PROVIDER loaded' AS status, COUNT(*) AS record_count FROM DIM_PROVIDER;
SELECT * FROM DIM_PROVIDER LIMIT 5;

-- STEP 2: LOAD DIM_PATIENT


INSERT INTO DIM_PATIENT (
    patient_id,
    patient_name,
    date_of_birth,
    race,
    ethnicity,
    gender,
    state,
    primary_provider_id,
    effective_date,
    is_current,
    version
)
SELECT 
    patient_id,
    name AS patient_name,
    TO_DATE(DOB, 'MM/DD/YYYY') AS date_of_birth,  -- Convert string to date
    race,
    ethnicity,
    gender,
    state,
    primary_provider_id,
    CURRENT_DATE() AS effective_date,
    TRUE AS is_current,
    1 AS version
FROM STG_PATIENT;

-- Verify
SELECT 'DIM_PATIENT loaded' AS status, COUNT(*) AS record_count FROM DIM_PATIENT;
SELECT * FROM DIM_PATIENT LIMIT 5;


-- STEP 3: LOAD DIM_DATE (Already populated - verify)


SELECT 'DIM_DATE' AS dimension, COUNT(*) AS record_count FROM DIM_DATE;


-- STEP 4: LOAD DIM_SERVICE (Unique service + modality combinations)


INSERT INTO DIM_SERVICE (
    service_performed,
    modality
)
SELECT DISTINCT
    service_performed,
    modality
FROM STG_VISIT
WHERE service_performed IS NOT NULL
  AND modality IS NOT NULL
ORDER BY service_performed, modality;

-- Verify
SELECT 'DIM_SERVICE loaded' AS status, COUNT(*) AS record_count FROM DIM_SERVICE;
SELECT * FROM DIM_SERVICE ORDER BY service_key;


-- STEP 5: LOAD FACT_VISIT (Main Fact Table)


INSERT INTO FACT_VISIT (
    patient_key,
    provider_key,
    date_key,
    service_key,
    visit_id,
    duration_minutes,
    assessment_score,
    q1_answer,
    q2_answer,
    q3_answer,
    q4_answer,
    q5_answer,
    q6_answer,
    q7_answer,
    q8_answer,
    q9_answer,
    q10_answer,
    has_assessment,
    is_group_visit,
    is_virtual_visit
)
SELECT 
    -- Lookup surrogate keys from dimensions
    dp.patient_key,
    dpr.provider_key,
    dd.date_key,
    ds.service_key,
    
    -- Degenerate dimension
    v.visit_id,
    
    -- Measures
    v.duration AS duration_minutes,
    a.assessment_score,
    
    -- Assessment question details
    a.q1_answer,
    a.q2_answer,
    a.q3_answer,
    a.q4_answer,
    a.q5_answer,
    a.q6_answer,
    a.q7_answer,
    a.q8_answer,
    a.q9_answer,
    a.q10_answer,
    
    
    CASE WHEN a.assessment_id IS NOT NULL THEN TRUE ELSE FALSE END AS has_assessment,
    CASE WHEN v.modality = 'group' THEN TRUE ELSE FALSE END AS is_group_visit,
    CASE WHEN v.modality = 'virtual' THEN TRUE ELSE FALSE END AS is_virtual_visit

FROM STG_VISIT v

-- Join to get dimension surrogate keys
INNER JOIN DIM_PATIENT dp 
    ON v.patient_id = dp.patient_id 
    AND dp.is_current = TRUE

INNER JOIN DIM_PROVIDER dpr 
    ON v.provider_id = dpr.provider_id 
    AND dpr.is_current = TRUE

INNER JOIN DIM_DATE dd 
    ON TO_NUMBER(TO_CHAR(TO_DATE(v.visit_date, 'MM/DD/YYYY'), 'YYYYMMDD')) = dd.date_key

INNER JOIN DIM_SERVICE ds 
    ON v.service_performed = ds.service_performed 
    AND v.modality = ds.modality

-- Left join to assessment (not all visits have assessments)
LEFT JOIN STG_ASSESSMENT a 
    ON v.visit_id = a.visit_id;

-- Verify
SELECT 'FACT_VISIT loaded' AS status, COUNT(*) AS record_count FROM FACT_VISIT;


-- FINAL VERIFICATION: All Tables


SELECT 'Summary of Star Schema:' AS info;

SELECT 'DIM_PROVIDER' AS table_name, COUNT(*) AS record_count FROM DIM_PROVIDER
UNION ALL SELECT 'DIM_PATIENT', COUNT(*) FROM DIM_PATIENT
UNION ALL SELECT 'DIM_DATE', COUNT(*) FROM DIM_DATE
UNION ALL SELECT 'DIM_SERVICE', COUNT(*) FROM DIM_SERVICE
UNION ALL SELECT 'FACT_VISIT', COUNT(*) FROM FACT_VISIT
ORDER BY table_name;




-- DATA QUALITY CHECKS


-- Check 1: All visits have patient dimension
SELECT 
    COUNT(*) AS total_visits,
    COUNT(DISTINCT patient_key) AS unique_patients,
    COUNT(DISTINCT provider_key) AS unique_providers
FROM FACT_VISIT;

-- Check 2: Assessment distribution
SELECT 
    has_assessment,
    COUNT(*) AS visit_count
FROM FACT_VISIT
GROUP BY has_assessment;

-- Expected:
-- has_assessment=TRUE: 22 visits (with assessment)
-- has_assessment=FALSE: 1 visit (without assessment - visit_id 51)

-- Check 3: Modality distribution
SELECT 
    CASE 
        WHEN is_group_visit THEN 'Group'
        WHEN is_virtual_visit THEN 'Virtual'
        ELSE 'In-Person/Individual'
    END AS visit_type,
    COUNT(*) AS count
FROM FACT_VISIT
GROUP BY 
    CASE 
        WHEN is_group_visit THEN 'Group'
        WHEN is_virtual_visit THEN 'Virtual'
        ELSE 'In-Person/Individual'
    END;

-- Check 4: Sample joined data
SELECT 
    dd.full_date AS visit_date,
    dp.patient_name,
    dpr.provider_name,
    ds.service_performed,
    ds.modality,
    fv.duration_minutes,
    fv.assessment_score,
    fv.has_assessment
FROM FACT_VISIT fv
INNER JOIN DIM_DATE dd ON fv.date_key = dd.date_key
INNER JOIN DIM_PATIENT dp ON fv.patient_key = dp.patient_key
INNER JOIN DIM_PROVIDER dpr ON fv.provider_key = dpr.provider_key
INNER JOIN DIM_SERVICE ds ON fv.service_key = ds.service_key
ORDER BY dd.full_date
LIMIT 10;


-- SAMPLE ANALYTICAL QUERIES


-- Query 1: Visits per Provider
SELECT 
    dpr.provider_name,
    dpr.specialty,
    COUNT(*) AS total_visits,
    AVG(fv.duration_minutes) AS avg_duration,
    COUNT(CASE WHEN fv.has_assessment THEN 1 END) AS visits_with_assessment
FROM FACT_VISIT fv
INNER JOIN DIM_PROVIDER dpr ON fv.provider_key = dpr.provider_key
GROUP BY dpr.provider_name, dpr.specialty
ORDER BY total_visits DESC;

-- Query 2: Visits per Month
SELECT 
    dd.year,
    dd.month_name,
    COUNT(*) AS total_visits,
    AVG(fv.assessment_score) AS avg_assessment_score
FROM FACT_VISIT fv
INNER JOIN DIM_DATE dd ON fv.date_key = dd.date_key
WHERE fv.has_assessment = TRUE
GROUP BY dd.year, dd.month, dd.month_name
ORDER BY dd.year, dd.month;

-- Query 3: Patient Demographics
SELECT 
    dp.state,
    dp.gender,
    COUNT(DISTINCT dp.patient_key) AS patient_count,
    COUNT(fv.visit_fact_key) AS total_visits
FROM DIM_PATIENT dp
LEFT JOIN FACT_VISIT fv ON dp.patient_key = fv.patient_key
GROUP BY dp.state, dp.gender
ORDER BY patient_count DESC;

-- Query 4: Group Therapy Analysis
SELECT 
    dd.full_date AS session_date,
    dpr.provider_name,
    ds.service_performed,
    COUNT(*) AS participant_count
FROM FACT_VISIT fv
INNER JOIN DIM_DATE dd ON fv.date_key = dd.date_key
INNER JOIN DIM_PROVIDER dpr ON fv.provider_key = dpr.provider_key
INNER JOIN DIM_SERVICE ds ON fv.service_key = ds.service_key
WHERE fv.is_group_visit = TRUE
GROUP BY dd.full_date, dpr.provider_name, ds.service_performed
ORDER BY dd.full_date;

-- Query 5: Patient Progress (Assessment Scores Over Time)
SELECT 
    dp.patient_name,
    dd.full_date AS visit_date,
    fv.assessment_score,
    LAG(fv.assessment_score) OVER (PARTITION BY dp.patient_key ORDER BY dd.full_date) AS previous_score,
    fv.assessment_score - LAG(fv.assessment_score) OVER (PARTITION BY dp.patient_key ORDER BY dd.full_date) AS score_change
FROM FACT_VISIT fv
INNER JOIN DIM_PATIENT dp ON fv.patient_key = dp.patient_key
INNER JOIN DIM_DATE dd ON fv.date_key = dd.date_key
WHERE fv.has_assessment = TRUE
ORDER BY dp.patient_name, dd.full_date;



