-- ============================================================================
-- DATA CLEANING PIPELINE: Netflix Movies & TV Shows Dataset (MySQL)
-- ============================================================================
-- Description: Preparing the raw `netflix_titles` dataset for analysis by 
--              creating a staging table, checking for duplicates, handling 
--              blank/unknown values, cleaning string formatting, and converting 
--              text dates into standard SQL DATE format.
-- ============================================================================

-- Initial check of raw data
SELECT *
FROM netflix_titles;

-- ============================================================================
-- STEP 1: Create Staging Table
-- Preserve the raw `netflix_titles` data by working in `netflix_staging`.
-- ============================================================================

CREATE TABLE netflix_staging
LIKE netflix_titles;

INSERT INTO netflix_staging
SELECT *
FROM netflix_titles;

SELECT *
FROM netflix_staging;

-- ============================================================================
-- STEP 2: Check for Duplicate Records
-- Partition across all core attributes to verify data uniqueness.
-- ============================================================================

WITH cte_duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY title, type, director, cast, country, date_added,
                            release_year, rating, duration, listed_in, description
           ) AS row_num
    FROM netflix_staging
)
SELECT *
FROM cte_duplicates
WHERE row_num > 1;

-- ============================================================================
-- STEP 3: Standardize Strings & Handle Blank / 'Unknown' Values
-- ============================================================================

-- 3.1 Clean `director` column: convert blank strings ('') and 'Unknown' placeholders to NULL
SELECT COUNT(*) AS blank_directors
FROM netflix_staging
WHERE director = '' OR director = 'Unknown';

UPDATE netflix_staging
SET director = NULL
WHERE director = '' OR director = 'Unknown';

-- 3.2 Clean `cast` column: convert blank strings ('') to NULL
UPDATE netflix_staging
SET cast = NULL
WHERE cast = '';

-- 3.3 Clean `country` column: remove leading commas/spaces (e.g., ', United States' -> 'United States')
SELECT DISTINCT country
FROM netflix_staging
ORDER BY 1;

UPDATE netflix_staging
SET country = TRIM(LEADING ', ' FROM country);

-- Convert remaining blank strings in `country` (69 records) to NULL
SELECT COUNT(*) AS blank_countries
FROM netflix_staging
WHERE country = '';

UPDATE netflix_staging
SET country = NULL
WHERE country = '';

-- ============================================================================
-- STEP 4: Date Parsing & Data Type Conversion
-- Convert `date_added` from text ('Month DD, YYYY') to SQL DATE format.
-- ============================================================================

-- Inspect raw `date_added` strings
SELECT date_added
FROM netflix_staging;

-- Handle any blank date strings before conversion
UPDATE netflix_staging
SET date_added = NULL
WHERE date_added = '';

-- Trim leading/trailing spaces and parse text date into YYYY-MM-DD format
UPDATE netflix_staging
SET date_added = STR_TO_DATE(TRIM(`date_added`), '%M %d, %Y');

-- Modify column data type from TEXT to DATE
ALTER TABLE netflix_staging
MODIFY COLUMN `date_added` DATE;

-- Final verification of cleaned staging table
SELECT *
FROM netflix_staging;
