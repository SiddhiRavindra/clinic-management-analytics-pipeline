/*

-- INSERT SAMPLE DATA INTO MENTAL HEALTH CLINIC DATABASE


USE mental_health_clinic;
GO


-- 1. INSERT DATA INTO PROVIDER TABLE (No dependencies)


INSERT INTO PROVIDER (name, specialty) VALUES
('Dr. Sarah Johnson', 'Clinical Psychologist'),
('Dr. Michael Chen', 'Psychiatrist'),
('Dr. Emily Rodriguez', 'Family Therapist'),
('Dr. James Williams', 'Cognitive Behavioral Therapist'),
('Dr. Lisa Anderson', 'Child Psychologist');
GO

SELECT * FROM PROVIDER;
GO


-- 2. INSERT DATA INTO PATIENT TABLE (References PROVIDER)


INSERT INTO PATIENT (name, DOB, race, ethnicity, gender, state, primary_provider_id) VALUES
('John Smith', '1985-03-15', 'White', 'Non-Hispanic', 'Male', 'California', 1),
('Maria Garcia', '1990-07-22', 'Hispanic', 'Hispanic', 'Female', 'Texas', 2),
('David Lee', '1978-11-30', 'Asian', 'Non-Hispanic', 'Male', 'New York', 1),
('Sarah Brown', '1995-05-10', 'Black', 'Non-Hispanic', 'Female', 'Florida', 3),
('Robert Wilson', '1982-09-18', 'White', 'Non-Hispanic', 'Male', 'Illinois', 2),
('Jennifer Martinez', '1988-12-25', 'Hispanic', 'Hispanic', 'Female', 'Arizona', 4),
('Michael Taylor', '1975-04-08', 'White', 'Non-Hispanic', 'Male', 'Washington', 5),
('Lisa Anderson', '1992-08-14', 'Black', 'Non-Hispanic', 'Female', 'Georgia', 3),
('William Kim', '1987-01-20', 'Asian', 'Non-Hispanic', 'Male', 'California', 1),
('Amanda White', '1993-06-05', 'White', 'Non-Hispanic', 'Female', 'Texas', 2);
GO

SELECT * FROM PATIENT;
GO


-- 3. INSERT DATA INTO VISIT TABLE (References PATIENT and PROVIDER)


-- Individual visits
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality) VALUES
-- Patient 1 (John Smith) visits
(1, 1, '2025-01-15', 60, 'Initial assessment', 'in-person'),
(1, 1, '2025-02-15', 50, 'Follow-up therapy', 'in-person'),
(1, 1, '2025-03-15', 50, 'Cognitive behavioral therapy', 'virtual'),

-- Patient 2 (Maria Garcia) visits
(2, 2, '2025-01-20', 45, 'Medication management', 'in-person'),
(2, 2, '2025-02-20', 30, 'Medication follow-up', 'virtual'),

-- Patient 3 (David Lee) visits
(3, 1, '2025-02-01', 60, 'Initial consultation', 'in-person'),
(3, 1, '2025-03-01', 50, 'Therapy session', 'in-person'),

-- Patient 4 (Sarah Brown) visits
(4, 3, '2025-01-10', 60, 'Family therapy intake', 'in-person'),
(4, 3, '2025-02-10', 90, 'Family therapy session', 'in-person'),

-- Patient 5 (Robert Wilson) visits
(5, 2, '2025-01-25', 45, 'Psychiatric evaluation', 'in-person'),
(5, 2, '2025-02-25', 30, 'Medication review', 'virtual'),

-- Patient 6 (Jennifer Martinez) visits
(6, 4, '2025-02-05', 60, 'CBT initial session', 'in-person'),
(6, 4, '2025-03-05', 50, 'CBT session', 'virtual'),

-- Patient 7 (Michael Taylor) visits
(7, 5, '2025-01-18', 60, 'Child assessment', 'in-person'),
(7, 5, '2025-02-18', 50, 'Play therapy', 'in-person'),

-- Patient 8 (Lisa Anderson) visits
(8, 3, '2025-02-12', 60, 'Couples therapy', 'in-person'),

-- Patient 9 (William Kim) visits
(9, 1, '2025-03-10', 50, 'Therapy session', 'virtual'),

-- Patient 10 (Amanda White) visits
(10, 2, '2025-03-20', 45, 'Medication consultation', 'in-person');

-- Group therapy visits (same date, same provider, multiple patients)
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality) VALUES
(1, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(3, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(6, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(9, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group');
GO

SELECT * FROM VISIT ORDER BY visit_date, visit_id;
GO


-- 4. INSERT DATA INTO ASSESSMENT TABLE (References VISIT)


-- Assessments for various visits (visit_id 1-20)
INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer, 
                        q6_answer, q7_answer, q8_answer, q9_answer, q10_answer) VALUES
-- Visit 1 - Initial assessment (moderate symptoms)
(1, 3, 4, 3, 4, 3, 3, 4, 3, 4, 3),

-- Visit 2 - Follow-up (improved)
(2, 2, 3, 2, 3, 2, 2, 3, 2, 3, 2),

-- Visit 3 - Continued improvement
(3, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1),

-- Visit 4 - Medication management (high symptoms initially)
(4, 4, 5, 4, 5, 4, 4, 5, 4, 4, 5),

-- Visit 5 - Follow-up (improved)
(5, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3),

-- Visit 6 - Initial consultation (moderate)
(6, 3, 3, 3, 3, 4, 3, 3, 3, 3, 3),

-- Visit 7 - Therapy session (improving)
(7, 2, 2, 3, 2, 3, 2, 2, 2, 2, 2),

-- Visit 8 - Family therapy (high stress)
(8, 4, 4, 5, 4, 4, 5, 4, 4, 4, 5),

-- Visit 9 - Family therapy follow-up (improved)
(9, 3, 3, 4, 3, 3, 4, 3, 3, 3, 3),

-- Visit 10 - Psychiatric evaluation (severe)
(10, 5, 5, 5, 4, 5, 5, 5, 4, 5, 5),

-- Visit 11 - Medication review (much improved)
(11, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2),

-- Visit 12 - CBT initial (moderate)
(12, 3, 4, 3, 3, 4, 3, 3, 3, 4, 3),

-- Visit 13 - CBT session (improving)
(13, 2, 3, 2, 2, 3, 2, 2, 2, 3, 2),

-- Visit 14 - Child assessment (mild)
(14, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2),

-- Visit 15 - Play therapy (improving)
(15, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1),

-- Visit 16 - Couples therapy (high conflict)
(16, 4, 5, 4, 4, 5, 4, 5, 4, 4, 5),

-- Visit 17 - Virtual therapy
(17, 2, 3, 2, 2, 3, 2, 3, 2, 2, 2),

-- Visit 18 - Medication consultation
(18, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3),

-- Visit 19-22 - Group therapy assessments (varied responses)
(19, 3, 3, 4, 3, 3, 3, 4, 3, 3, 3),
(20, 2, 3, 3, 2, 3, 2, 3, 2, 3, 2),
(21, 3, 4, 3, 3, 4, 3, 3, 3, 4, 3),
(22, 2, 2, 3, 2, 3, 2, 2, 2, 3, 2);
GO

SELECT * FROM ASSESSMENT;
GO


-- VERIFICATION QUERIES


PRINT '========================================';
PRINT 'DATA INSERTION COMPLETE!';
PRINT '========================================';
PRINT '';

-- Count records in each table
PRINT 'Record Counts:';
SELECT 'PROVIDER' AS TableName, COUNT(*) AS RecordCount FROM PROVIDER
UNION ALL
SELECT 'PATIENT', COUNT(*) FROM PATIENT
UNION ALL
SELECT 'VISIT', COUNT(*) FROM VISIT
UNION ALL
SELECT 'ASSESSMENT', COUNT(*) FROM ASSESSMENT;
GO

-- Show sample data with relationships
PRINT '';
PRINT 'Sample Patient Visit Data:';
SELECT 
    p.name AS PatientName,
    pr.name AS ProviderName,
    v.visit_date AS VisitDate,
    v.modality AS Modality,
    a.assessment_score AS AssessmentScore
FROM PATIENT p
JOIN VISIT v ON p.patient_id = v.patient_id
JOIN PROVIDER pr ON v.provider_id = pr.provider_id
LEFT JOIN ASSESSMENT a ON v.visit_id = a.visit_id
ORDER BY v.visit_date, p.name;
GO

-- Show group therapy participants
PRINT '';
PRINT 'Group Therapy Session (2025-03-22):';
SELECT 
    p.name AS PatientName,
    pr.name AS ProviderName,
    v.visit_date,
    v.service_performed,
    a.assessment_score
FROM PATIENT p
JOIN VISIT v ON p.patient_id = v.patient_id
JOIN PROVIDER pr ON v.provider_id = pr.provider_id
LEFT JOIN ASSESSMENT a ON v.visit_id = a.visit_id
WHERE v.modality = 'group' AND v.visit_date = '2025-03-22'
ORDER BY p.name;
GO

PRINT '';
PRINT '========================================';
PRINT 'ALL DATA INSERTED AND VERIFIED!';
PRINT '========================================';
GO

*/


-- INSERT SAMPLE DATA INTO MENTAL HEALTH CLINIC DATABASE


USE mental_health_clinic;
GO


-- 1. INSERT DATA INTO PROVIDER TABLE (No dependencies)


INSERT INTO PROVIDER (name, specialty) VALUES
('Dr. Sarah Johnson', 'Clinical Psychologist'),
('Dr. Michael Chen', 'Psychiatrist'),
('Dr. Emily Rodriguez', 'Family Therapist'),
('Dr. James Williams', 'Cognitive Behavioral Therapist'),
('Dr. Lisa Anderson', 'Child Psychologist');
GO

SELECT * FROM PROVIDER;
GO


-- 2. INSERT DATA INTO PATIENT TABLE (References PROVIDER)

INSERT INTO PATIENT (name, DOB, race, ethnicity, gender, state, primary_provider_id) VALUES
('John Smith', '1985-03-15', 'White', 'Non-Hispanic', 'Male', 'California', 1),
('Maria Garcia', '1990-07-22', 'Hispanic', 'Hispanic', 'Female', 'Texas', 2),
('David Lee', '1978-11-30', 'Asian', 'Non-Hispanic', 'Male', 'New York', 1),
('Sarah Brown', '1995-05-10', 'Black', 'Non-Hispanic', 'Female', 'Florida', 3),
('Robert Wilson', '1982-09-18', 'White', 'Non-Hispanic', 'Male', 'Illinois', 2),
('Jennifer Martinez', '1988-12-25', 'Hispanic', 'Hispanic', 'Female', 'Arizona', 4),
('Michael Taylor', '1975-04-08', 'White', 'Non-Hispanic', 'Male', 'Washington', 5),
('Lisa Anderson', '1992-08-14', 'Black', 'Non-Hispanic', 'Female', 'Georgia', 3),
('William Kim', '1987-01-20', 'Asian', 'Non-Hispanic', 'Male', 'California', 1),
('Amanda White', '1993-06-05', 'White', 'Non-Hispanic', 'Female', 'Texas', 2);
GO

SELECT * FROM PATIENT;
GO


-- 3. INSERT DATA INTO VISIT TABLE (References PATIENT and PROVIDER)


-- Individual visits
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality) VALUES
-- Patient 1 (John Smith) visits
(1, 1, '2025-01-15', 60, 'Initial assessment', 'in-person'),
(1, 1, '2025-02-15', 50, 'Follow-up therapy', 'in-person'),
(1, 1, '2025-03-15', 50, 'Cognitive behavioral therapy', 'virtual'),

-- Patient 2 (Maria Garcia) visits
(2, 2, '2025-01-20', 45, 'Medication management', 'in-person'),
(2, 2, '2025-02-20', 30, 'Medication follow-up', 'virtual'),

-- Patient 3 (David Lee) visits
(3, 1, '2025-02-01', 60, 'Initial consultation', 'in-person'),
(3, 1, '2025-03-01', 50, 'Therapy session', 'in-person'),

-- Patient 4 (Sarah Brown) visits
(4, 3, '2025-01-10', 60, 'Family therapy intake', 'in-person'),
(4, 3, '2025-02-10', 90, 'Family therapy session', 'in-person'),

-- Patient 5 (Robert Wilson) visits
(5, 2, '2025-01-25', 45, 'Psychiatric evaluation', 'in-person'),
(5, 2, '2025-02-25', 30, 'Medication review', 'virtual'),

-- Patient 6 (Jennifer Martinez) visits
(6, 4, '2025-02-05', 60, 'CBT initial session', 'in-person'),
(6, 4, '2025-03-05', 50, 'CBT session', 'virtual'),

-- Patient 7 (Michael Taylor) visits
(7, 5, '2025-01-18', 60, 'Child assessment', 'in-person'),
(7, 5, '2025-02-18', 50, 'Play therapy', 'in-person'),

-- Patient 8 (Lisa Anderson) visits
(8, 3, '2025-02-12', 60, 'Couples therapy', 'in-person'),

-- Patient 9 (William Kim) visits
(9, 1, '2025-03-10', 50, 'Therapy session', 'virtual'),

-- Patient 10 (Amanda White) visits
(10, 2, '2025-03-20', 45, 'Medication consultation', 'in-person');

-- Group therapy visits (same date, same provider, multiple patients)
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality) VALUES
(1, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(3, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(6, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group'),
(9, 3, '2025-03-22', 90, 'Group therapy - Anxiety management', 'group');
GO

SELECT * FROM VISIT ORDER BY visit_date, visit_id;
GO


-- 4. INSERT DATA INTO ASSESSMENT TABLE (References VISIT)


-- Assessments for various visits (visit_id 1-20)
INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer, 
                        q6_answer, q7_answer, q8_answer, q9_answer, q10_answer) VALUES
-- Visit 1 - Initial assessment (moderate symptoms)
(1, 3, 4, 3, 4, 3, 3, 4, 3, 4, 3),

-- Visit 2 - Follow-up (improved)
(2, 2, 3, 2, 3, 2, 2, 3, 2, 3, 2),

-- Visit 3 - Continued improvement
(3, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1),

-- Visit 4 - Medication management (high symptoms initially)
(4, 4, 5, 4, 5, 4, 4, 5, 4, 4, 5),

-- Visit 5 - Follow-up (improved)
(5, 3, 3, 3, 4, 3, 3, 3, 3, 3, 3),

-- Visit 6 - Initial consultation (moderate)
(6, 3, 3, 3, 3, 4, 3, 3, 3, 3, 3),

-- Visit 7 - Therapy session (improving)
(7, 2, 2, 3, 2, 3, 2, 2, 2, 2, 2),

-- Visit 8 - Family therapy (high stress)
(8, 4, 4, 5, 4, 4, 5, 4, 4, 4, 5),

-- Visit 9 - Family therapy follow-up (improved)
(9, 3, 3, 4, 3, 3, 4, 3, 3, 3, 3),

-- Visit 10 - Psychiatric evaluation (severe)
(10, 5, 5, 5, 4, 5, 5, 5, 4, 5, 5),

-- Visit 11 - Medication review (much improved)
(11, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2),

-- Visit 12 - CBT initial (moderate)
(12, 3, 4, 3, 3, 4, 3, 3, 3, 4, 3),

-- Visit 13 - CBT session (improving)
(13, 2, 3, 2, 2, 3, 2, 2, 2, 3, 2),

-- Visit 14 - Child assessment (mild)
(14, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2),

-- Visit 15 - Play therapy (improving)
(15, 1, 2, 1, 2, 2, 1, 2, 1, 2, 1),

-- Visit 16 - Couples therapy (high conflict)
(16, 4, 5, 4, 4, 5, 4, 5, 4, 4, 5),

-- Visit 17 - Virtual therapy
(17, 2, 3, 2, 2, 3, 2, 3, 2, 2, 2),

-- Visit 18 - Medication consultation
(18, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3),

-- Visit 19-22 - Group therapy assessments (varied responses)
(19, 3, 3, 4, 3, 3, 3, 4, 3, 3, 3),
(20, 2, 3, 3, 2, 3, 2, 3, 2, 3, 2),
(21, 3, 4, 3, 3, 4, 3, 3, 3, 4, 3),
(22, 2, 2, 3, 2, 3, 2, 2, 2, 3, 2);
GO

SELECT * FROM ASSESSMENT;
GO


-- VERIFICATION QUERIES


PRINT '========================================';
PRINT 'DATA INSERTION COMPLETE!';
PRINT '========================================';
PRINT '';

-- Count records in each table
PRINT 'Record Counts:';
SELECT 'PROVIDER' AS TableName, COUNT(*) AS RecordCount FROM PROVIDER
UNION ALL
SELECT 'PATIENT', COUNT(*) FROM PATIENT
UNION ALL
SELECT 'VISIT', COUNT(*) FROM VISIT
UNION ALL
SELECT 'ASSESSMENT', COUNT(*) FROM ASSESSMENT;
GO

-- Show sample data with relationships
PRINT '';
PRINT 'Sample Patient Visit Data:';
SELECT 
    p.name AS PatientName,
    pr.name AS ProviderName,
    v.visit_date AS VisitDate,
    v.modality AS Modality,
    a.assessment_score AS AssessmentScore
FROM PATIENT p
JOIN VISIT v ON p.patient_id = v.patient_id
JOIN PROVIDER pr ON v.provider_id = pr.provider_id
LEFT JOIN ASSESSMENT a ON v.visit_id = a.visit_id
ORDER BY v.visit_date, p.name;
GO

-- Show group therapy participants
PRINT '';
PRINT 'Group Therapy Session (2025-03-22):';
SELECT 
    p.name AS PatientName,
    pr.name AS ProviderName,
    v.visit_date,
    v.service_performed,
    a.assessment_score
FROM PATIENT p
JOIN VISIT v ON p.patient_id = v.patient_id
JOIN PROVIDER pr ON v.provider_id = pr.provider_id
LEFT JOIN ASSESSMENT a ON v.visit_id = a.visit_id
WHERE v.modality = 'group' AND v.visit_date = '2025-03-22'
ORDER BY p.name;
GO

PRINT '';
PRINT '========================================';
PRINT 'ALL DATA INSERTED AND VERIFIED!';
PRINT '========================================';
GO