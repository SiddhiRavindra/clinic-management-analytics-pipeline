USE mental_health_clinic;
GO

-- Drop and recreate the view with correct data types
DROP VIEW IF EXISTS vw_PatientAssessmentDue;
GO

CREATE VIEW vw_PatientAssessmentDue
AS
SELECT 
    p.patient_id,
    p.name AS patient_name,
    pr.name AS primary_provider,
    last_assessment.last_assessment_date,
    CASE 
        WHEN last_assessment.last_assessment_date IS NULL THEN 'First visit - assessment required'
        WHEN DATEDIFF(DAY, last_assessment.last_assessment_date, GETDATE()) >= 90 THEN 'Due for assessment'
        ELSE 'Not due yet'
    END AS assessment_status,
    CASE 
        WHEN last_assessment.last_assessment_date IS NULL THEN NULL
        ELSE DATEDIFF(DAY, last_assessment.last_assessment_date, GETDATE())
    END AS days_since_last_assessment,
    CASE 
        WHEN last_assessment.last_assessment_date IS NULL THEN NULL
        ELSE 90 - DATEDIFF(DAY, last_assessment.last_assessment_date, GETDATE())
    END AS days_until_next_due
FROM PATIENT p
INNER JOIN PROVIDER pr ON p.primary_provider_id = pr.provider_id
LEFT JOIN (
    SELECT 
        v.patient_id,
        MAX(v.visit_date) AS last_assessment_date
    FROM ASSESSMENT a
    INNER JOIN VISIT v ON a.visit_id = v.visit_id
    GROUP BY v.patient_id
) last_assessment ON p.patient_id = last_assessment.patient_id;
GO

PRINT 'View: vw_PatientAssessmentDue fixed';
GO

--
-- CLEAN UP THE EXISTING DATA


-- assessments violate the 3-month rule
PRINT '';
PRINT '--- Checking for assessments that violate 3-month rule ---';

SELECT 
    a1.assessment_id,
    v1.patient_id,
    p.name AS patient_name,
    v1.visit_date AS current_assessment_date,
    v2.visit_date AS previous_assessment_date,
    DATEDIFF(DAY, v2.visit_date, v1.visit_date) AS days_between_assessments,
    CASE 
        WHEN DATEDIFF(DAY, v2.visit_date, v1.visit_date) < 90 THEN 'VIOLATION'
        ELSE 'OK'
    END AS status
FROM ASSESSMENT a1
INNER JOIN VISIT v1 ON a1.visit_id = v1.visit_id
INNER JOIN PATIENT p ON v1.patient_id = p.patient_id
CROSS APPLY (
    SELECT TOP 1 v.visit_date
    FROM ASSESSMENT a
    INNER JOIN VISIT v ON a.visit_id = v.visit_id
    WHERE v.patient_id = v1.patient_id
    AND a.assessment_id < a1.assessment_id
    ORDER BY v.visit_date DESC
) v2
WHERE DATEDIFF(DAY, v2.visit_date, v1.visit_date) < 90
ORDER BY v1.patient_id, v1.visit_date;
GO

--
-- OPTION 1: Delete assessments that violate the rule
--

PRINT '';
PRINT '--- Option 1: Delete violating assessments ---';
PRINT 'Run this if you want to remove assessments that are too close together:';
PRINT '';
PRINT '/*';
PRINT 'DELETE a1';
PRINT 'FROM ASSESSMENT a1';
PRINT 'INNER JOIN VISIT v1 ON a1.visit_id = v1.visit_id';
PRINT 'WHERE EXISTS (';
PRINT '    SELECT 1';
PRINT '    FROM ASSESSMENT a2';
PRINT '    INNER JOIN VISIT v2 ON a2.visit_id = v2.visit_id';
PRINT '    WHERE v2.patient_id = v1.patient_id';
PRINT '    AND a2.assessment_id < a1.assessment_id';
PRINT '    AND DATEDIFF(DAY, v2.visit_date, v1.visit_date) < 90';
PRINT ');';
PRINT '*/';
GO


DROP TRIGGER IF EXISTS trg_ValidateAssessmentTiming;
GO

CREATE TRIGGER trg_ValidateAssessmentTiming
ON ASSESSMENT
INSTEAD OF INSERT  -- Changed from AFTER to INSTEAD OF
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @visit_id INT;
    DECLARE @patient_id INT;
    DECLARE @visit_date DATE;
    DECLARE @last_assessment_date DATE;
    DECLARE @days_since_last_assessment INT;
    DECLARE @is_first_assessment BIT;
    
    -- Cursor to handle multiple inserts
    DECLARE assessment_cursor CURSOR FOR
    SELECT visit_id FROM inserted;
    
    OPEN assessment_cursor;
    FETCH NEXT FROM assessment_cursor INTO @visit_id;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Get visit and patient details
        SELECT 
            @patient_id = v.patient_id,
            @visit_date = v.visit_date
        FROM VISIT v
        WHERE v.visit_id = @visit_id;
        
        -- Check if this patient has any previous assessments
        SELECT TOP 1 @last_assessment_date = v.visit_date
        FROM ASSESSMENT a
        INNER JOIN VISIT v ON a.visit_id = v.visit_id
        WHERE v.patient_id = @patient_id
        ORDER BY v.visit_date DESC;
        
        -- Determine if this is the first assessment
        IF @last_assessment_date IS NULL
        BEGIN
            SET @is_first_assessment = 1;
        END
        ELSE
        BEGIN
            SET @is_first_assessment = 0;
            SET @days_since_last_assessment = DATEDIFF(DAY, @last_assessment_date, @visit_date);
        END
        
        -- Validation logic
        IF @is_first_assessment = 1
        BEGIN
            -- Allow first assessment
            INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                                   q6_answer, q7_answer, q8_answer, q9_answer, q10_answer)
            SELECT visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                   q6_answer, q7_answer, q8_answer, q9_answer, q10_answer
            FROM inserted
            WHERE visit_id = @visit_id;
            
            PRINT 'Assessment accepted: First assessment for patient ' + CAST(@patient_id AS VARCHAR);
        END
        ELSE IF @days_since_last_assessment >= 90
        BEGIN
            -- Allow assessment after 3 months
            INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                                   q6_answer, q7_answer, q8_answer, q9_answer, q10_answer)
            SELECT visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                   q6_answer, q7_answer, q8_answer, q9_answer, q10_answer
            FROM inserted
            WHERE visit_id = @visit_id;
            
            PRINT 'Assessment accepted: ' + CAST(@days_since_last_assessment AS VARCHAR) + 
                  ' days since last assessment';
        END
        ELSE
        BEGIN
            -- Reject assessment
            DECLARE @error_msg NVARCHAR(500);
            SET @error_msg = 'Assessment REJECTED for Patient ' + CAST(@patient_id AS VARCHAR) + 
                           ': Only ' + CAST(@days_since_last_assessment AS VARCHAR) + 
                           ' days since last assessment on ' + 
                           CONVERT(VARCHAR, @last_assessment_date, 107) + 
                           '. Next assessment allowed in ' + 
                           CAST(90 - @days_since_last_assessment AS VARCHAR) + ' days.';
            
            CLOSE assessment_cursor;
            DEALLOCATE assessment_cursor;
            
            RAISERROR(@error_msg, 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        FETCH NEXT FROM assessment_cursor INTO @visit_id;
    END
    
    CLOSE assessment_cursor;
    DEALLOCATE assessment_cursor;
END;
GO

PRINT 'Trigger: trg_ValidateAssessmentTiming FIXED and recreated';
GO



PRINT '';
PRINT '========================================';
PRINT 'TESTING FIXED TRIGGER';
PRINT '========================================';
PRINT '';

-- Test 1: View current assessment status
PRINT '--- Current Assessment Status ---';
SELECT * FROM vw_PatientAssessmentDue
ORDER BY 
    CASE assessment_status
        WHEN 'First visit - assessment required' THEN 1
        WHEN 'Due for assessment' THEN 2
        ELSE 3
    END,
    patient_id;
GO

-- Test 2: Try to insert assessment too soon for patient 1
PRINT '';
PRINT '--- Test: Insert assessment too soon (should fail) ---';

DECLARE @test_visit_id INT;

-- Create a visit for patient 1 today
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
VALUES (1, 1, GETDATE(), 50, 'Test follow-up', 'in-person');

SET @test_visit_id = SCOPE_IDENTITY();
PRINT 'Test visit created: ' + CAST(@test_visit_id AS VARCHAR);

-- Try to insert assessment (should fail)
BEGIN TRY
    INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                           q6_answer, q7_answer, q8_answer, q9_answer, q10_answer)
    VALUES (@test_visit_id, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2);
    
    PRINT 'ERROR: Assessment was inserted (should have been rejected!)';
END TRY
BEGIN CATCH
    PRINT 'SUCCESS: Assessment rejected as expected';
    PRINT 'Error message: ' + ERROR_MESSAGE();
END CATCH;

-- Clean up test data
DELETE FROM VISIT WHERE visit_id = @test_visit_id;
PRINT 'Test data cleaned up';
GO

-- Test 3: Check a patient who hasn't had any assessments
PRINT '';
PRINT '--- Test: Patient without assessment (should allow) ---';

-- Find a patient with visits but no assessments
DECLARE @patient_no_assessment INT;
DECLARE @test_visit_id2 INT;

SELECT TOP 1 @patient_no_assessment = v.patient_id
FROM VISIT v
WHERE NOT EXISTS (
    SELECT 1 
    FROM ASSESSMENT a
    INNER JOIN VISIT v2 ON a.visit_id = v2.visit_id
    WHERE v2.patient_id = v.patient_id
)
GROUP BY v.patient_id;

IF @patient_no_assessment IS NOT NULL
BEGIN
    PRINT 'Testing with Patient ID: ' + CAST(@patient_no_assessment AS VARCHAR);
    
    -- Create a visit
    INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
    VALUES (@patient_no_assessment, 1, GETDATE(), 60, 'First assessment visit', 'in-person');
    
    SET @test_visit_id2 = SCOPE_IDENTITY();
    
    -- Try to insert assessment (should succeed)
    BEGIN TRY
        INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                               q6_answer, q7_answer, q8_answer, q9_answer, q10_answer)
        VALUES (@test_visit_id2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3);
        
        PRINT 'SUCCESS: First assessment inserted';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: First assessment was rejected (should have been allowed!)';
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
    
    -- Clean up
    DELETE FROM ASSESSMENT WHERE visit_id = @test_visit_id2;
    DELETE FROM VISIT WHERE visit_id = @test_visit_id2;
    PRINT 'Test data cleaned up';
END
ELSE
BEGIN
    PRINT 'No patient found without assessments';
END;
GO

PRINT 'END';

GO