-- Set database to multi-user mode
ALTER DATABASE mental_health_clinic SET MULTI_USER;
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