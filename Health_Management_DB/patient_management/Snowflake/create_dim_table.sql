
-- SETUP: Create Database and Schema


-- Set your role and warehouse
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Create database
CREATE DATABASE IF NOT EXISTS mental_health_clinic_dw;

-- Switch to the database
USE DATABASE mental_health_clinic_dw;

-- Create schema
CREATE SCHEMA IF NOT EXISTS star_schema;

-- Switch to the schema
USE SCHEMA star_schema;

-- Verify
SELECT 
    CURRENT_DATABASE() AS current_db,
    CURRENT_SCHEMA() AS current_schema;

-- This should return:
-- current_db: MENTAL_HEALTH_CLINIC_DW
-- current_schema: STAR_SCHEMA-- =====================================================
-- SETUP: Create Database and Schema
-- =====================================================

-- Set your role and warehouse
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Create database
CREATE DATABASE IF NOT EXISTS mental_health_clinic_dw;

-- Switch to the database
USE DATABASE mental_health_clinic_dw;

-- Create schema
CREATE SCHEMA IF NOT EXISTS star_schema;

-- Switch to the schema
USE SCHEMA star_schema;

-- Verify
SELECT 
    CURRENT_DATABASE() AS current_db,
    CURRENT_SCHEMA() AS current_schema;

-- This should return:
-- current_db: MENTAL_HEALTH_CLINIC_DW
-- current_schema: STAR_SCHEMA-- =====================================================
-- SETUP: Create Database and Schema
-- =====================================================

-- Set your role and warehouse
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Create database
CREATE DATABASE IF NOT EXISTS mental_health_clinic_dw;

-- Switch to the database
USE DATABASE mental_health_clinic_dw;

-- Create schema
CREATE SCHEMA IF NOT EXISTS star_schema;

-- Switch to the schema
USE SCHEMA star_schema;

-- Verify
SELECT 
    CURRENT_DATABASE() AS current_db,
    CURRENT_SCHEMA() AS current_schema;

-- This should return:
-- current_db: MENTAL_HEALTH_CLINIC_DW
-- current_schema: STAR_SCHEMA

-- Now you can run: USE SCHEMA star_schema;
USE SCHEMA star_schema;

-- Create DIM_PROVIDER
CREATE OR REPLACE TABLE DIM_PROVIDER (
    provider_key INTEGER AUTOINCREMENT PRIMARY KEY,
    provider_id INTEGER NOT NULL,
    provider_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    effective_date DATE DEFAULT CURRENT_DATE(),
    expiration_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    row_created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

CREATE OR REPLACE TABLE DIM_PATIENT (
    patient_key INTEGER AUTOINCREMENT PRIMARY KEY,
    patient_id INTEGER NOT NULL,
    patient_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    gender VARCHAR(20),
    state VARCHAR(50),
    primary_provider_id INTEGER NOT NULL,
    
    -- Type 2 SCD
    effective_date DATE DEFAULT CURRENT_DATE(),
    expiration_date DATE,
    is_current BOOLEAN DEFAULT TRUE,
    version INTEGER DEFAULT 1,
    
    -- Audit
    row_created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. DIM_DATE (Standard Date Dimension)
CREATE OR REPLACE TABLE DIM_DATE (
    date_key INTEGER PRIMARY KEY,
    full_date DATE NOT NULL,
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    month_name VARCHAR(10) NOT NULL,
    quarter INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(10) NOT NULL,
    is_weekend BOOLEAN NOT NULL
);



-- 4. DIM_SERVICE (Simple - From VISIT table)
CREATE OR REPLACE TABLE DIM_SERVICE (
    service_key INTEGER AUTOINCREMENT PRIMARY KEY,
    service_performed VARCHAR(200) NOT NULL,
    modality VARCHAR(50) NOT NULL,
    
    -- Audit
    row_created_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);



-- FACT TABLE (SIMPLIFIED)


CREATE OR REPLACE TABLE FACT_VISIT (
    visit_fact_key INTEGER AUTOINCREMENT PRIMARY KEY,
    
    -- Dimension Keys
    patient_key INTEGER NOT NULL,
    provider_key INTEGER NOT NULL,
    date_key INTEGER NOT NULL,
    service_key INTEGER NOT NULL,
    
    -- Degenerate Dimensions
    visit_id INTEGER NOT NULL,
    
    -- Measures
    duration_minutes INTEGER NOT NULL,
    assessment_score INTEGER,
    
    -- Assessment Details (10 questions)
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
    
    -- Flags
    has_assessment BOOLEAN NOT NULL,
    is_group_visit BOOLEAN NOT NULL,
    is_virtual_visit BOOLEAN NOT NULL,
    
    -- Audit
    etl_loaded_date TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    
    -- Foreign Keys
    CONSTRAINT fk_fact_patient FOREIGN KEY (patient_key) REFERENCES DIM_PATIENT(patient_key),
    CONSTRAINT fk_fact_provider FOREIGN KEY (provider_key) REFERENCES DIM_PROVIDER(provider_key),
    CONSTRAINT fk_fact_date FOREIGN KEY (date_key) REFERENCES DIM_DATE(date_key),
    CONSTRAINT fk_fact_service FOREIGN KEY (service_key) REFERENCES DIM_SERVICE(service_key)
);

