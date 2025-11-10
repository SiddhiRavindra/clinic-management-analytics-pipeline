select * from PATIENT;
select * from ASSESSMENT;
select * from provider;
select * from VISIT;
select * from AUDIT_LOG;

-- Test Case 1 :Primary rovider
-- Added forgein key in patients to connect it with primary provider from provider table 
select p.patient_id,p.name,p.primary_provider_id,p1.provider_id, p1.name from patient p
join PROVIDER p1 on p.primary_provider_id=p1.provider_id;


-- Test Case 2 : Prevent exact duplicate visits in Visit Table:
-- Test if trigger prevents duplicates NOW
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
VALUES (1, 1, '2025-03-15', 50, 'Test duplicate', 'in-person');

-- Test Case 3: Check Duplicates in Visits and Delete them incase required:
select * from visit;
-- Verification Ways to check check duplicate visits if needed : Shows Duplicate visit entries.
-- This finds actual duplicates (same patient, same provider, same date, modality service_perfomed)

-- Show complete details of duplicate visits
SELECT 
    v.*
FROM VISIT v
WHERE EXISTS (
    SELECT 1
    FROM VISIT v2
    WHERE v2.patient_id = v.patient_id
      AND v2.provider_id = v.provider_id
      AND v2.visit_date = v.visit_date
      AND v2.service_performed=v.service_performed
      AND v2.modality=v.modality
      AND v2.visit_id != v.visit_id
)
ORDER BY patient_id, provider_id, visit_date;

--delet duplicates :
-- DELETE duplicates (keep only the first occurrence)
WITH DuplicateVisits AS (
    SELECT 
        visit_id,
        ROW_NUMBER() OVER (
            PARTITION BY patient_id, provider_id, visit_date 
            ORDER BY visit_id
        ) AS rn
    FROM VISIT
)
DELETE FROM VISIT
WHERE visit_id IN (
    SELECT visit_id 
    FROM DuplicateVisits 
    WHERE rn > 1
);


-- Test Case 4: Inser new visit record
-- Create a new visit for testing
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
VALUES (1, 1, GETDATE(), 50, 'Test visit', 'in-person');

--Test case 5 : Insert new assessment :
-- Create visit and insert assessment (should SUCCEED)
INSERT INTO VISIT (patient_id, provider_id, visit_date, duration, service_performed, modality)
VALUES (2, 1, GETDATE(), 50, 'Test visit', 'in-person');

INSERT INTO ASSESSMENT (visit_id, q1_answer, q2_answer, q3_answer, q4_answer, q5_answer,
                        q6_answer, q7_answer, q8_answer, q9_answer, q10_answer)
VALUES (SCOPE_IDENTITY(), 3, 3, 3, 3, 3, 3, 3, 3, 3, 3);

--Test case 6: 10 patients with high assessment score
--10 patients having higher assessment score :


select top 10 visit_date, patient_id,name,assessment_score
from 
(
select v.visit_date, p.patient_id,p.name,a.assessment_score,
ROW_NUMBER() over(partition by p.patient_id order by a.assessment_score desc) as rn
from 
patient p
join visit v on v.patient_id=p.patient_id
join ASSESSMENT a on a.visit_id=v.visit_id
) AS temp
where rn=1
order by assessment_score desc;

-- Test case 7 : Average Daily visit :
--average visit per day :
SELECT avg(visit_count) AS average_visits_per_day
FROM (
    SELECT visit_date, COUNT(*) AS visit_count
    FROM visit 
    GROUP BY visit_date
) AS daily_visits;

select * from visit;

--Test case 8: Group visit :
--identify group visit :

select 
    v.visit_date,
    v.modality,
    p.name as patient,
    p1.name as doctor,
    v.service_performed
from visit v
join PATIENT p on v.patient_id = p.patient_id
join PROVIDER p1 on v.provider_id = p1.provider_id
where v.modality = 'group'  
order by v.visit_date, p1.name;

-- visit Date shouldn't be in future and visit must past 90days for next assessment : 
DECLARE @allowed3 BIT;
DECLARE @msg3 NVARCHAR(500);
DECLARE @future_date DATE;  

--Test case 9 : Future Visit Date and Assessment before 90days to next visit not allowed :
-- Calculate future date first
SET @future_date = DATEADD(DAY, 30, GETDATE());  

EXEC sp_CheckAssessmentAllowed 
    @patient_id = 1, 
    @visit_date = @future_date,  
    @is_allowed = @allowed3 OUTPUT, 
    @message = @msg3 OUTPUT;

SELECT 'Test 3: Future Date' AS test, @allowed3 AS IsAllowed, @msg3 AS Message;





