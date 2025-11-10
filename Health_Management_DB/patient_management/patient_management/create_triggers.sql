
-- ESSENTIAL TRIGGERS FOR MENTAL HEALTH CLINIC DATABASE


USE mental_health_clinic;
GO


-- 1. AUDIT LOG TABLE (for tracking changes)


CREATE TABLE AUDIT_LOG (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation_type VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    record_id INT NOT NULL,
    old_value NVARCHAR(MAX),
    new_value NVARCHAR(MAX),
    changed_by VARCHAR(100) DEFAULT SYSTEM_USER,
    changed_date DATETIME DEFAULT GETDATE()
);
GO

PRINT 'Audit Log Table Created';
GO


-- 2. TRIGGER: Prevent Deletion of Providers with Active Patients


CREATE OR ALTER TRIGGER trg_PreventProviderDeletion
ON PROVIDER
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if any provider being deleted has active patients
    IF EXISTS (
        SELECT 1 
        FROM deleted d
        INNER JOIN PATIENT p ON d.provider_id = p.primary_provider_id
    )
    BEGIN
        RAISERROR('Cannot delete provider: Provider has active patients assigned. Please reassign patients first.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- If no active patients, allow deletion
    DELETE FROM PROVIDER 
    WHERE provider_id IN (SELECT provider_id FROM deleted);
    
    PRINT 'Provider(s) deleted successfully';
END;
GO

PRINT 'Trigger: trg_PreventProviderDeletion created';
GO


-- 3. TRIGGER: Audit Patient Updates


CREATE OR ALTER TRIGGER trg_AuditPatientChanges
ON PATIENT
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AUDIT_LOG (table_name, operation_type, record_id, old_value, new_value)
    SELECT 
        'PATIENT',
        'UPDATE',
        i.patient_id,
        CONCAT('Name: ', d.name, ', DOB: ', d.DOB, ', Primary Provider: ', d.primary_provider_id),
        CONCAT('Name: ', i.name, ', DOB: ', i.DOB, ', Primary Provider: ', i.primary_provider_id)
    FROM inserted i
    INNER JOIN deleted d ON i.patient_id = d.patient_id;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' patient record(s) audited';
END;
GO

PRINT 'Trigger: trg_AuditPatientChanges created';
GO


-- 4. TRIGGER: Validate Visit Date (Cannot be in future)


CREATE OR ALTER TRIGGER trg_ValidateVisitDate
ON VISIT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM inserted WHERE visit_date > GETDATE())
    BEGIN
        RAISERROR('Visit date cannot be in the future', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger: trg_ValidateVisitDate created';
GO


-- 5. TRIGGER: Prevent Overlapping Appointments for Same Patient


CREATE OR ALTER TRIGGER trg_PreventOverlappingVisits
ON VISIT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Check if patient has overlapping visits on the same day with same provider
    IF EXISTS (
        SELECT 1
        FROM inserted i
        INNER JOIN VISIT v ON i.patient_id = v.patient_id 
                           AND i.provider_id = v.provider_id
                           AND i.visit_date = v.visit_date
                           AND i.visit_id != v.visit_id
    )
    BEGIN
        RAISERROR('Patient already has a visit scheduled with this provider on this date', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger: trg_PreventOverlappingVisits created';
GO


-- 6. TRIGGER: Audit Assessment Changes


CREATE OR ALTER TRIGGER trg_AuditAssessmentChanges
ON ASSESSMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- For INSERT operations
    IF NOT EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO AUDIT_LOG (table_name, operation_type, record_id, old_value, new_value)
        SELECT 
            'ASSESSMENT',
            'INSERT',
            i.assessment_id,
            NULL,
            CONCAT('Visit ID: ', i.visit_id, ', Score: ', i.assessment_score)
        FROM inserted i;
    END
    ELSE
    BEGIN
        -- For UPDATE operations
        INSERT INTO AUDIT_LOG (table_name, operation_type, record_id, old_value, new_value)
        SELECT 
            'ASSESSMENT',
            'UPDATE',
            i.assessment_id,
            CONCAT('Score: ', d.assessment_score),
            CONCAT('Score: ', i.assessment_score)
        FROM inserted i
        INNER JOIN deleted d ON i.assessment_id = d.assessment_id
        WHERE d.assessment_score != i.assessment_score;
    END
END;
GO

PRINT 'Trigger: trg_AuditAssessmentChanges created';
GO


-- 7. TRIGGER: Ensure Assessment Belongs to Valid Visit


CREATE OR ALTER TRIGGER trg_ValidateAssessmentVisit
ON ASSESSMENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        LEFT JOIN VISIT v ON i.visit_id = v.visit_id
        WHERE v.visit_id IS NULL
    )
    BEGIN
        RAISERROR('Assessment must be associated with a valid visit', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger: trg_ValidateAssessmentVisit created';
GO


-- 8. TRIGGER: Log Visit Deletions


CREATE OR ALTER TRIGGER trg_LogVisitDeletion
ON VISIT
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AUDIT_LOG (table_name, operation_type, record_id, old_value, new_value)
    SELECT 
        'VISIT',
        'DELETE',
        d.visit_id,
        CONCAT('Patient ID: ', d.patient_id, ', Provider ID: ', d.provider_id, ', Date: ', d.visit_date),
        NULL
    FROM deleted d;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' visit deletion(s) logged';
END;
GO

PRINT 'Trigger: trg_LogVisitDeletion created';
GO


-- 9. TRIGGER: Validate Patient Age (Must be at least 5 years old)


CREATE OR ALTER TRIGGER trg_ValidatePatientAge
ON PATIENT
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT 1 
        FROM inserted 
        WHERE DATEDIFF(YEAR, DOB, GETDATE()) < 5
    )
    BEGIN
        RAISERROR('Patient must be at least 5 years old', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

PRINT 'Trigger: trg_ValidatePatientAge created';
GO


-- 10. TRIGGER: Prevent Multiple Assessments on Same Visit (Optional)

-- Comment: This is optional - you may want multiple assessments per visit
-- Uncomment if you want to enforce one assessment per visit

/*
CREATE OR ALTER TRIGGER trg_PreventMultipleAssessments
ON ASSESSMENT
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (
        SELECT visit_id
        FROM ASSESSMENT
        WHERE visit_id IN (SELECT visit_id FROM inserted)
        GROUP BY visit_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR('A visit can only have one assessment', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO
*/


-- 11. TRIGGER: Auto-create Audit Log for Patient Deletion


CREATE OR ALTER TRIGGER trg_LogPatientDeletion
ON PATIENT
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO AUDIT_LOG (table_name, operation_type, record_id, old_value, new_value)
    SELECT 
        'PATIENT',
        'DELETE',
        d.patient_id,
        CONCAT('Name: ', d.name, ', DOB: ', d.DOB, ', Primary Provider: ', d.primary_provider_id),
        NULL
    FROM deleted d;
    
    PRINT CAST(@@ROWCOUNT AS VARCHAR) + ' patient deletion(s) logged';
END;
GO

PRINT 'Trigger: trg_LogPatientDeletion created';
GO


-- VERIFICATION: List all triggers


PRINT '';
PRINT '========================================';
PRINT 'ALL TRIGGERS CREATED SUCCESSFULLY!';
PRINT '========================================';
PRINT '';

SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS TableName,
    te.type_desc AS TriggerType,
    CASE 
        WHEN te.type_desc = 'AFTER' THEN 'Fires after the operation'
        WHEN te.type_desc = 'INSTEAD_OF' THEN 'Replaces the operation'
        ELSE 'Other'
    END AS Description
FROM sys.triggers t
INNER JOIN sys.trigger_events te ON t.object_id = te.object_id
WHERE t.parent_class = 1  -- Object or column triggers
  AND OBJECT_NAME(t.parent_id) IN ('PROVIDER', 'PATIENT', 'VISIT', 'ASSESSMENT')
GROUP BY t.name, t.parent_id, te.type_desc
ORDER BY OBJECT_NAME(t.parent_id), t.name;
GO


-- TEST THE TRIGGERS


PRINT '';
PRINT '========================================';
PRINT 'TESTING TRIGGERS';
PRINT '========================================';
PRINT '';

-- Test 1: Try to insert a future visit (should fail)
PRINT '--- Test 1: Attempting to insert future visit (should fail) ---';
BEGIN TRY
    INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
    VALUES (1, 1, '2026-12-31', 60, 'Future appointment', 'in-person');
END TRY
BEGIN CATCH
    PRINT 'Error caught (EXPECTED): ' + ERROR_MESSAGE();
END CATCH;
GO

-- Test 2: Update a patient (should be logged in audit)
PRINT '';
PRINT '--- Test 2: Updating patient record (should be audited) ---';
UPDATE PATIENT 
SET state = 'New York' 
WHERE patient_id = 1;

SELECT TOP 1 * FROM AUDIT_LOG ORDER BY audit_id DESC;
GO

-- Test 3: Try to insert patient under 5 years old (should fail)
PRINT '';
PRINT '--- Test 3: Attempting to insert patient under 5 years old (should fail) ---';
BEGIN TRY
    INSERT INTO PATIENT (name, DOB, race, ethnicity, gender, state, primary_provider_id)
    VALUES ('Baby Smith', '2023-01-01', 'White', 'Non-Hispanic', 'Male', 'Texas', 1);
END TRY
BEGIN CATCH
    PRINT 'Error caught (EXPECTED): ' + ERROR_MESSAGE();
END CATCH;
GO

PRINT '';
PRINT '========================================';
PRINT 'TRIGGER TESTING COMPLETE!';
PRINT '========================================';
GO