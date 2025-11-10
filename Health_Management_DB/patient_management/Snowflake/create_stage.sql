-- =====================================================
-- LOAD EACH FILE SEPARATELY USING SQL
-- =====================================================

USE DATABASE mental_health_clinic_dw;
USE SCHEMA star_schema;

-- =====================================================
-- STEP 1: CREATE STAGE (if not exists)
-- =====================================================

CREATE STAGE IF NOT EXISTS my_stage;

-- Verify all 4 files are uploaded
LIST @my_stage;



-- STEP 2: CREATE FILE FORMAT


CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE
    TRIM_SPACE = TRUE;

-- STEP 3: CREATE STAGING TABLES (SEPARATELY)


-- Table 1: PROVIDER (3 columns)
CREATE OR REPLACE TABLE STG_PROVIDER (
    provider_id INTEGER,
    name VARCHAR(100),
    specialty VARCHAR(100)
);

-- Table 2: PATIENT (8 columns)
CREATE OR REPLACE TABLE STG_PATIENT (
    patient_id INTEGER,
    name VARCHAR(100),
    DOB VARCHAR(20),
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    gender VARCHAR(20),
    state VARCHAR(50),
    primary_provider_id INTEGER
);

-- Table 3: VISIT (7 columns)
CREATE OR REPLACE TABLE STG_VISIT (
    visit_id INTEGER,
    patient_id INTEGER,
    provider_id INTEGER,
    visit_date VARCHAR(20),
    duration INTEGER,
    service_performed VARCHAR(200),
    modality VARCHAR(50)
);

-- Table 4: ASSESSMENT (13 columns)
CREATE OR REPLACE TABLE STG_ASSESSMENT (
    assessment_id INTEGER,
    visit_id INTEGER,
    q1_answer INTEGER,
    q2_answer INTEGER,
    q3_answer INTEGER,
    q4_answer INTEGER,
    q5_answer INTEGER,
    q6_answer INTEGER,
    q7_answer INTEGER,
    q8_answer INTEGER,
    q9_answer INTEGER,
    q10_answer INTEGER,
    assessment_score INTEGER
);


-- STEP 4: LOAD EACH FILE SEPARATELY


-- Load File 1: provider.csv
COPY INTO STG_PROVIDER
FROM @my_stage/provider.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

SELECT 'PROVIDER loaded:' AS status, COUNT(*) AS records FROM STG_PROVIDER;

-- Load File 2: patient.csv
COPY INTO STG_PATIENT
FROM @my_stage/patient.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

SELECT 'PATIENT loaded:' AS status, COUNT(*) AS records FROM STG_PATIENT;

-- Load File 3: visit.csv
COPY INTO STG_VISIT
FROM @my_stage/visit.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

SELECT 'VISIT loaded:' AS status, COUNT(*) AS records FROM STG_VISIT;

-- Load File 4: assessment.csv (check if it's 'assesment.csv' or 'assessment.csv')
COPY INTO STG_ASSESSMENT
FROM @my_stage/assesment.csv  -- Your file has this spelling
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

SELECT 'ASSESSMENT loaded:' AS status, COUNT(*) AS records FROM STG_ASSESSMENT;

-- STEP 5: VERIFY ALL LOADED


SELECT 'Load Summary:' AS info;

SELECT 'STG_PROVIDER' AS table_name, COUNT(*) AS records FROM STG_PROVIDER
UNION ALL SELECT 'STG_PATIENT', COUNT(*) FROM STG_PATIENT
UNION ALL SELECT 'STG_VISIT', COUNT(*) FROM STG_VISIT
UNION ALL SELECT 'STG_ASSESSMENT', COUNT(*) FROM STG_ASSESSMENT
ORDER BY table_name;

-- Expected:
-- STG_ASSESSMENT: 44 records
-- STG_PATIENT: 20 records
-- STG_PROVIDER: 10 records
-- STG_VISIT: 23 records

-- =====================================================
-- STEP 6: PREVIEW DATA
-- =====================================================

SELECT * FROM STG_PROVIDER LIMIT 5;
SELECT * FROM STG_PATIENT LIMIT 5;
SELECT * FROM STG_VISIT LIMIT 5;
SELECT * FROM STG_ASSESSMENT LIMIT 5;

