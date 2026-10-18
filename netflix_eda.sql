-- ============================================================================
-- EXPLORATORY DATA ANALYSIS (EDA): Netflix Movies & TV Shows Dataset (MySQL)
-- ============================================================================
-- Description: Analyzing the Netflix catalog (`netflix_staging`) to understand 
--              content distribution, production geography, seasonal release 
--              patterns, audience maturity ratings, and data quality anomalies.
-- ============================================================================

-- Initial check of the staging dataset
SELECT *
FROM netflix_staging;

-- ============================================================================
-- STEP 1: Data Quality & Anomaly Checks
-- ============================================================================

-- 1.1 Check for missing values in the `country` column
SELECT COUNT(*) AS missing_country_count
FROM netflix_staging
WHERE country IS NULL;

-- 1.2 Check for logical date anomalies (titles with release year in the future)
SELECT *
FROM netflix_staging
WHERE release_year > 2026;

-- 1.3 Inspect unique values in `rating` to ensure no corrupted entries exist
SELECT DISTINCT rating
FROM netflix_staging;

-- ============================================================================
-- STEP 2: Content Distribution (Movies vs. TV Shows & Genres)
-- ============================================================================

-- 2.1 Total count and percentage share of Movies vs. TV Shows
SELECT 
    type, 
    COUNT(*) AS total_titles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM netflix_staging
GROUP BY type;

-- 2.2 Most popular genre combinations (`listed_in`) broken down by content type
SELECT type, listed_in, COUNT(*) AS title_count
FROM netflix_staging
GROUP BY type, listed_in
ORDER BY title_count DESC;

-- ============================================================================
-- STEP 3: Geographic & Creator Analysis
-- ============================================================================

-- 3.1 Top countries producing content on Netflix
SELECT country, COUNT(*) AS total_titles
FROM netflix_staging
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC;

-- 3.2 Top 10 most prolific directors on the platform
SELECT director, COUNT(*) AS total_titles
FROM netflix_staging
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total_titles DESC
LIMIT 10;

-- ============================================================================
-- STEP 4: Temporal Trends & Seasonality
-- ============================================================================

-- 4.1 Content volume by original release year
SELECT release_year, COUNT(*) AS total_titles
FROM netflix_staging
GROUP BY release_year
ORDER BY release_year DESC;

-- 4.2 Average release year by content type (checking whether Movies or TV Shows are newer on average)
SELECT type, ROUND(AVG(release_year), 0) AS avg_release_year
FROM netflix_staging
GROUP BY type;

-- 4.3 Seasonality analysis: Which months see the highest volume of new additions?
SELECT MONTH(date_added) AS month_added, COUNT(*) AS titles_added
FROM netflix_staging
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added)
ORDER BY month_added ASC;

-- ============================================================================
-- STEP 5: Audience Maturity & Rating Analysis (with Window Functions)
-- ============================================================================

-- 5.1 Overall distribution of maturity ratings
SELECT rating, COUNT(*) AS total_titles
FROM netflix_staging
GROUP BY rating
ORDER BY total_titles DESC;

-- 5.2 Breakdown of ratings by content type (Movies vs. TV Shows)
SELECT type, rating, COUNT(*) AS total_titles
FROM netflix_staging
GROUP BY type, rating
ORDER BY total_titles DESC;

-- 5.3 Top 3 most common maturity ratings for EACH content type using CTE & DENSE_RANK()
WITH Rating_Counts AS (
    SELECT 
        type, 
        rating, 
        COUNT(*) AS total_titles,
        DENSE_RANK() OVER(PARTITION BY type ORDER BY COUNT(*) DESC) AS rating_rank
    FROM netflix_staging
    WHERE rating IS NOT NULL
    GROUP BY type, rating
)
SELECT type, rating, total_titles, rating_rank
FROM Rating_Counts
WHERE rating_rank <= 3;
