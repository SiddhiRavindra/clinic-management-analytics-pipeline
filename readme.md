# Health Care Clinic Data Warehouse

End-to-end healthcare analytics solution: SQL Server OLTP → Snowflake Data Warehouse → Power BI Dashboards

## Overview

A comprehensive data engineering project implementing a complete analytics pipeline for a mental health clinic, from transactional database design to business intelligence reporting.

## Architecture
```
SQL Server OLTP → CSV Export → Snowflake Star Schema → Power BI Dashboards
```

## Problem Statement

Mental health clinic needed:
- Centralized patient and provider data management
- Automated assessment compliance (first visit + every 90 days)
- Provider workload balancing insights
- Patient outcome tracking and reporting
- Regulatory compliance (HIPAA audit trail)

## Solution

### 1. SQL Server OLTP Database
Normalized relational database (3NF) with automated business rules:
- 4 core tables: PROVIDER, PATIENT, VISIT, ASSESSMENT
- 11 automated triggers enforcing business logic
- Assessment timing automation (first visit + 90-day intervals)
- Comprehensive audit trail for compliance
- Prevents data integrity issues (duplicate visits, invalid dates, orphaned records)

### 2. Snowflake Data Warehouse
Star schema optimized for analytics:
- 1 Fact table: FACT_VISIT (23 visit records)
- 4 Dimension tables: DIM_PROVIDER, DIM_PATIENT, DIM_DATE, DIM_SERVICE
- ETL pipeline from SQL Server via CSV staging
- Supports complex analytical queries with sub-second performance

### 3. Power BI Dashboards
Interactive business intelligence reporting:
- 5 dashboard pages for different stakeholders
- 15+ DAX measures for business metrics
- Real-time filtering and drill-through capabilities
- Visualizations for provider performance, patient demographics, service utilization

## Technologies

- **Database:** SQL Server 2022
- **Data Warehouse:** Snowflake Cloud
- **ETL:** SQL-based transformations
- **BI Tool:** Microsoft Power BI
- **Languages:** T-SQL, SQL, DAX

## Key Features

### Automated Business Rules
- **Assessment Timing:** First visit required, then every 90 days (96% compliance achieved)
- **Provider Protection:** Cannot delete providers with active patients
- **Duplicate Prevention:** No overlapping appointments for same patient
- **Date Validation:** No future visit dates allowed
- **Age Validation:** Minimum patient age of 5 years

### Database Design
- Normalized OLTP schema (3NF) with referential integrity
- Star schema data warehouse with Type 2 SCD support
- 4 foreign key relationships maintaining data consistency
- 15+ check constraints for data validation

### Analytics Capabilities
- Monthly visit trends and provider workload analysis
- Patient demographics and geographic distribution
- Assessment compliance monitoring and outcome tracking
- Service utilization by type and modality
- Patient progress over time with severity classification

## Project Structure
```
├── 01_database_design/          # ERD diagrams and data dictionary
├── 02_sql_server_oltp/          # OLTP database scripts and triggers
├── 03_snowflake_star_schema/    # Star schema DDL and ETL scripts
├── 04_etl_staging/              # Staging tables and data loading
├── 05_sample_data/              # Anonymized sample CSV files
├── 06_power_bi/                 # Dashboard file and DAX measures
├── 07_documentation/            # Technical and business documentation
└── 08_testing/                  # Test queries and validation scripts
```

## Database Schema

### OLTP Schema (SQL Server)
- **PROVIDER:** Healthcare providers (10 records)
- **PATIENT:** Patient demographics (20 records)
- **VISIT:** Clinical appointments (23 records)
- **ASSESSMENT:** Mental health questionnaires (44 records)

### Star Schema (Snowflake)
- **FACT_VISIT:** Visit transactions with assessment scores (Grain: one row per visit)
- **DIM_PROVIDER:** Provider attributes and specialty
- **DIM_PATIENT:** Patient demographics and primary provider
- **DIM_DATE:** Time dimension (2020-2030, 4,018 days)
- **DIM_SERVICE:** Service types and delivery modalities

## Key Metrics

- Total Patients: 20
- Total Visits: 23
- Assessment Completion Rate: 96%
- Average Assessment Score: 30.5 (Mild-Moderate severity)
- Total Clinical Hours: 20.5 hours

## Business Rules Implemented

1. Assessment required at first visit and every 90 days thereafter
2. Cannot delete providers with assigned patients
3. No duplicate appointments (same patient, provider, date)
4. Visit dates must be current or historical (no future dates)
5. Patients must be at least 5 years old
6. All data changes logged for audit compliance

## Sample Queries

**Top 10 Patients by Assessment Score:**
```sql
SELECT TOP 10 patient_id, name, assessment_score
FROM (
    SELECT p.patient_id, p.name, a.assessment_score,
           ROW_NUMBER() OVER(PARTITION BY p.patient_id ORDER BY a.assessment_score DESC) AS rn
    FROM PATIENT p
    JOIN VISIT v ON v.patient_id = p.patient_id
    JOIN ASSESSMENT a ON a.visit_id = v.visit_id
) AS ranked
WHERE rn = 1
ORDER BY assessment_score DESC;
```

**Identify Group Therapy Sessions:**
```sql
SELECT v.visit_date, p.name AS patient, pr.name AS provider, v.service_performed
FROM VISIT v
JOIN PATIENT p ON v.patient_id = p.patient_id
JOIN PROVIDER pr ON v.provider_id = pr.provider_id
WHERE v.modality = 'group'
ORDER BY v.visit_date;
```

## Skills Demonstrated

- Relational database design and normalization
- SQL Server T-SQL programming
- Trigger development for business logic automation
- Star schema dimensional modeling
- Cloud data warehousing (Snowflake)
- ETL pipeline development
- Data validation and quality assurance
- DAX measure creation
- Interactive dashboard design
- Healthcare domain knowledge
- HIPAA compliance considerations
- Technical documentation

## Installation

### Prerequisites
- SQL Server 2022 or higher
- Snowflake account
- Power BI Desktop
- Git

### Setup Steps
1. Clone repository: `git clone https://github.com/SiddhiRavindra/clinic-management-analytics-pipeline.git`
2. Run SQL Server scripts in `02_sql_server_oltp/` folder in order
3. Execute Snowflake scripts in `03_snowflake_star_schema/` folder
4. Load sample data from `05_sample_data/`
5. Open Power BI file from `06_power_bi/` folder
6. Configure Snowflake connection in Power BI

Detailed instructions in `/07_documentation/` folder.

## Results

- 100% business requirement compliance
- Automated enforcement of clinical protocols
- Zero manual assessment tracking needed
- Real-time compliance monitoring dashboard
- Scalable to 10,000+ visits annually
- Sub-second query performance on analytical workloads

## Project Highlights

- Implemented complex business logic with 11 SQL triggers
- Achieved 96% assessment compliance through automation
- Designed scalable star schema supporting multi-year analysis
- Created executive-ready Power BI dashboards with 5 analytical views
- Maintained complete audit trail for regulatory compliance

## Documentation

Complete documentation available in `/07_documentation/`:
- Technical specifications
- Business requirements
- User guides
- Data dictionary
- ERD diagrams

## Author

Siddhi Dhamale  
Data Engineering Student  
Email: siddhidhamale@example.com  
LinkedIn: [Your LinkedIn Profile]

## License

This project is available under the MIT License.

## Acknowledgments

Developed as an extension of a technical assessment for a Data Engineering Co-op position, demonstrating comprehensive data engineering capabilities from database design through business intelligence.
