-- ========================================
-- US Household Income Analysis SQL Script
-- ========================================
-- This script contains queries for data cleaning, exploratory data analysis (EDA),
-- and insights generation from the US Household Income dataset.
--
-- Datasets Used:
-- 1. USHouseholdIncome.csv: Contains geographic and demographic income data.
-- 2. USHouseholdIncome_Statistics.csv: Includes statistical metrics (mean, median, etc.).
--
-- Objectives:
-- 1. Clean and preprocess the dataset to ensure consistency and accuracy.
-- 2. Analyze the data for trends and insights related to income and geography.
-- 3. Highlight relationships between land area, water area, and household income.
--
-- Usage Instructions:
-- - Ensure the datasets are imported into the database.
-- - Execute the queries sequentially for optimal results.

-- ========================================
-- 1. DATA CLEANING
-- ========================================

-- 1.1 Resolving Duplicate Records
-- Identify duplicate entries by ID
SELECT id, COUNT(id)
FROM us_household_income
GROUP BY id
HAVING COUNT(id) > 1;

-- Remove duplicate records, keeping the first occurrence
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT row_id, id, ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) AS row_num
        FROM us_household_income
    ) AS temp_table
    WHERE row_num > 1
);

-- 1.2 Resolving Inconsistent State Names
-- Correct misspelled state names
UPDATE us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia';

UPDATE us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama';

-- 1.3 Fixing Missing Place Data
-- Fill in missing place names based on County and City
UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County' AND City = 'Vinemont';

-- 1.4 Unifying Type Definitions
-- Standardize type names (e.g., 'Boroughs' to 'Borough')
UPDATE us_household_income
SET Type = 'Borough'
WHERE Type = 'Boroughs';

-- ========================================
-- 2. EXPLORATORY DATA ANALYSIS (EDA)
-- ========================================

-- 2.1 Land and Water Area Analysis
-- Total land and water area by state
SELECT State_Name, SUM(ALand) AS Total_Land, SUM(AWater) AS Total_Water
FROM us_household_income
GROUP BY State_Name
ORDER BY Total_Land DESC;

-- Top 10 states by land area
SELECT State_Name, SUM(ALand) AS Total_Land
FROM us_household_income
GROUP BY State_Name
ORDER BY Total_Land DESC
LIMIT 10;

-- Top 10 states by water area
SELECT State_Name, SUM(AWater) AS Total_Water
FROM us_household_income
GROUP BY State_Name
ORDER BY Total_Water DESC
LIMIT 10;

-- 2.2 Income Analysis
-- Mean and median incomes by state
SELECT u.State_Name, ROUND(AVG(Mean), 1) AS Avg_Mean, ROUND(AVG(Median), 1) AS Avg_Median
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE MEAN <> 0
GROUP BY u.State_Name
ORDER BY Avg_Mean DESC;

-- Income statistics by type
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1) AS Avg_Mean, ROUND(AVG(Median), 1) AS Avg_Median
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE Mean <> 0
GROUP BY Type
ORDER BY Avg_Mean DESC;

-- Identifying regions with high representation (Types with >100 entries)
SELECT Type, COUNT(Type), ROUND(AVG(Mean), 1) AS Avg_Mean, ROUND(AVG(Median), 1) AS Avg_Median
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE Mean <> 0
GROUP BY Type
HAVING COUNT(Type) > 100
ORDER BY Avg_Median DESC;

-- Income trends by city
SELECT u.State_Name, City, ROUND(AVG(Mean), 1) AS Avg_Income
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
GROUP BY u.State_Name, City
ORDER BY Avg_Income DESC;

-- ========================================
-- 3. DATA VALIDATION AND INTEGRITY CHECKS
-- ========================================

-- Validate missing or zero land and water areas
SELECT ALand, AWater
FROM us_household_income
WHERE (AWater = 0 OR AWater IS NULL)
   OR (ALand = 0 OR ALand IS NULL);

-- Verify unmatched records between the two datasets
SELECT *
FROM us_household_income u
RIGHT JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE u.id IS NULL;

-- Verify income statistics for non-zero mean values
SELECT *
FROM us_household_income u
INNER JOIN us_household_income_statistics us
    ON u.id = us.id
WHERE Mean <> 0;

-- ========================================
-- END OF SCRIPT
-- ========================================
