-- 
-- DROP EXISTING TABLES IN CORRECT ORDER
-- 

USE mental_health_clinic;
GO

-- Drop tables in reverse order of dependencies
IF OBJECT_ID('ASSESSMENT', 'U') IS NOT NULL
    DROP TABLE ASSESSMENT;
GO

IF OBJECT_ID('VISIT', 'U') IS NOT NULL
    DROP TABLE VISIT;
GO

IF OBJECT_ID('PATIENT', 'U') IS NOT NULL
    DROP TABLE PATIENT;
GO

IF OBJECT_ID('PROVIDER', 'U') IS NOT NULL
    DROP TABLE PROVIDER;
GO

PRINT 'All existing tables dropped successfully.';
GO

-- 
-- CREATE TABLES
-- 

-- 1. PROVIDER Table (Must be created first - no dependencies)
CREATE TABLE PROVIDER (
    provider_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    CONSTRAINT chk_provider_name CHECK (LEN(TRIM(name)) > 0)
);
GO

-- 2. PATIENT Table (References PROVIDER)
CREATE TABLE PATIENT (
    patient_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    DOB DATE NOT NULL,
    race VARCHAR(50),
    ethnicity VARCHAR(50),
    gender VARCHAR(20),
    state VARCHAR(50),
    primary_provider_id INT NOT NULL,
    
    -- Foreign Key Constraint
    CONSTRAINT fk_patient_provider 
        FOREIGN KEY (primary_provider_id) 
        REFERENCES PROVIDER(provider_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT chk_patient_name CHECK (LEN(TRIM(name)) > 0),
    CONSTRAINT chk_patient_dob CHECK (DOB <= GETDATE()),
    CONSTRAINT chk_patient_gender CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say'))
);
GO

-- 3. VISIT Table (References PATIENT and PROVIDER)
CREATE TABLE VISIT (
    visit_id INT IDENTITY(1,1) PRIMARY KEY,
    patient_id INT NOT NULL,
    provider_id INT NOT NULL,
    visit_date DATE NOT NULL,
    duration INT NOT NULL,
    service_performed VARCHAR(200),
    modality VARCHAR(50),
    
    -- Foreign Key Constraints
    CONSTRAINT fk_visit_patient 
        FOREIGN KEY (patient_id) 
        REFERENCES PATIENT(patient_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    
    CONSTRAINT fk_visit_provider 
        FOREIGN KEY (provider_id) 
        REFERENCES PROVIDER(provider_id)
        ON DELETE NO ACTION
        ON UPDATE NO ACTION,
    
    -- Check Constraints
    CONSTRAINT chk_visit_date CHECK (visit_date <= GETDATE()),
    CONSTRAINT chk_visit_duration CHECK (duration > 0),
    CONSTRAINT chk_visit_modality CHECK (modality IN ('individual', 'group', 'virtual', 'in-person'))
);
GO

-- 4. ASSESSMENT Table (References VISIT)
CREATE TABLE ASSESSMENT (
    assessment_id INT IDENTITY(1,1) PRIMARY KEY,
    visit_id INT NOT NULL,
    q1_answer INT NOT NULL,
    q2_answer INT NOT NULL,
    q3_answer INT NOT NULL,
    q4_answer INT NOT NULL,
    q5_answer INT NOT NULL,
    q6_answer INT NOT NULL,
    q7_answer INT NOT NULL,
    q8_answer INT NOT NULL,
    q9_answer INT NOT NULL,
    q10_answer INT NOT NULL,
    assessment_score AS (
        q1_answer + q2_answer + q3_answer + q4_answer + q5_answer + 
        q6_answer + q7_answer + q8_answer + q9_answer + q10_answer
    ) PERSISTED,
    
    -- Foreign Key Constraint
    CONSTRAINT fk_assessment_visit 
        FOREIGN KEY (visit_id) 
        REFERENCES VISIT(visit_id)
        ON DELETE CASCADE
        ON UPDATE NO ACTION,
    
    -- Check Constraints (each answer must be 1-5)
    CONSTRAINT chk_q1_answer CHECK (q1_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q2_answer CHECK (q2_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q3_answer CHECK (q3_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q4_answer CHECK (q4_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q5_answer CHECK (q5_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q6_answer CHECK (q6_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q7_answer CHECK (q7_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q8_answer CHECK (q8_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q9_answer CHECK (q9_answer BETWEEN 1 AND 5),
    CONSTRAINT chk_q10_answer CHECK (q10_answer BETWEEN 1 AND 5)
);
GO

-- 
-- CREATE INDEXES FOR PERFORMANCE
-- 

-- Index on foreign keys
CREATE INDEX idx_patient_provider ON PATIENT(primary_provider_id);
CREATE INDEX idx_visit_patient ON VISIT(patient_id);
CREATE INDEX idx_visit_provider ON VISIT(provider_id);
CREATE INDEX idx_visit_date ON VISIT(visit_date);
CREATE INDEX idx_assessment_visit ON ASSESSMENT(visit_id);

-- Composite index for group visits
CREATE INDEX idx_visit_group ON VISIT(visit_date, provider_id, modality);
GO

-- 
-- VERIFY TABLE CREATION
-- 

PRINT '========================================';
PRINT 'ALL TABLES CREATED SUCCESSFULLY';
PRINT '========================================';
GO

-- Show all tables
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME;
GO

-- Show column details for each table
PRINT CHAR(10) + '--- PROVIDER Table ---';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PROVIDER'
ORDER BY ORDINAL_POSITION;

PRINT CHAR(10) + '--- PATIENT Table ---';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'PATIENT'
ORDER BY ORDINAL_POSITION;

PRINT CHAR(10) + '--- VISIT Table ---';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'VISIT'
ORDER BY ORDINAL_POSITION;

PRINT CHAR(10) + '--- ASSESSMENT Table ---';
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'ASSESSMENT'
ORDER BY ORDINAL_POSITION;
GO

-- Show foreign key relationships
PRINT CHAR(10) + '--- FOREIGN KEY RELATIONSHIPS ---';
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    COL_NAME(fc.parent_object_id, fc.parent_column_id) AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    COL_NAME(fc.referenced_object_id, fc.referenced_column_id) AS ReferencedColumn,
    delete_referential_action_desc AS OnDelete,
    update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fc 
    ON fk.object_id = fc.constraint_object_id
ORDER BY TableName, ForeignKeyName;
GO

-- Show all indexes
PRINT CHAR(10) + '--- INDEXES ---';
SELECT 
    OBJECT_NAME(i.object_id) AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType
FROM sys.indexes i
WHERE OBJECT_NAME(i.object_id) IN ('PROVIDER', 'PATIENT', 'VISIT', 'ASSESSMENT')
    AND i.name IS NOT NULL
ORDER BY TableName, IndexName;
GO

PRINT CHAR(10) + '===========';
PRINT 'DATABASE SETUP COMPLETE!';
PRINT '==========';
GO


-- Refresh connection
USE mental_health_clinic;
GO

-- Verify tables exist
SELECT TABLE_NAME 
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE' 
ORDER BY TABLE_NAME;
GO