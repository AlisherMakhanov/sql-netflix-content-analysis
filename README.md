# 🎬 Netflix Catalog — End-to-End SQL Data Cleaning & EDA

## 📌 Project Overview
In this end-to-end SQL project, I transformed raw Netflix catalog data (`netflix_titles`) into an analysis-ready staging table (`netflix_staging`) and conducted an **Exploratory Data Analysis (EDA)** in **MySQL**. The goal was to ensure high data quality and uncover key insights into Netflix's content strategy, geographical production hubs, release seasonality, and target audience maturity ratings.

### 📂 Repository Structure
* 🧹 **[1. Data Cleaning Script (`netflix_data_cleaning.sql`)](./netflix_data_cleaning.sql)** — Staging setup, deduplication check, NULL standardization, string trimming, and date parsing.
* 📊 **[2. Exploratory Data Analysis Script (`netflix_eda.sql`)](./netflix_eda.sql)** — Content distribution, geographical footprint, seasonality trends, and window function rankings.

---

## 🛠️ SQL Skills Demonstrated
* **Database:** MySQL 8.0
* **Data Cleaning:** Staging Table Architecture, Deduplication (`ROW_NUMBER() OVER`), String Trimming (`TRIM(LEADING ', ' FROM ...)`), NULL Standardization, Date Parsing (`STR_TO_DATE` with `'%M %d, %Y'`), Schema Alteration (`ALTER TABLE MODIFY COLUMN`).
* **Data Analysis (EDA):** Multi-dimensional Aggregations (`COUNT`, `AVG`, `ROUND`, `GROUP BY`), Window Functions (`SUM() OVER()`, `DENSE_RANK() OVER(PARTITION BY ...)`), Common Table Expressions (`WITH` / CTEs), Seasonality Extraction (`MONTH()`).

---

## 🧹 Phase 1: Data Cleaning Pipeline (`netflix_data_cleaning.sql`)

1. **Staging Table Creation:** Cloned `netflix_titles` into `netflix_staging` to preserve raw data integrity.
2. **Duplicate Verification:** Used a CTE with `ROW_NUMBER()` partitioned across all columns to check for duplicate rows.
3. **String Cleanup & NULL Standardization:**
   * Replaced blank strings (`''`) and `'Unknown'` placeholders in `director`, `cast`, and `country` with `NULL`.
   * Stripped leading comma artifacts from country names using `TRIM(LEADING ', ' FROM country)`.
4. **Date Formatting:** Parsed raw text dates (e.g., `'September 25, 2021'`) into native SQL `DATE` format:

```sql
UPDATE netflix_staging
SET date_added = STR_TO_DATE(TRIM(`date_added`), '%M %d, %Y');

ALTER TABLE netflix_staging
MODIFY COLUMN `date_added` DATE;
```

---

## 🔍 Phase 2: Exploratory Data Analysis (`netflix_eda.sql`)

### 1. Catalog Composition (Movies vs. TV Shows)
Calculated both absolute title counts and relative percentage share using a window function.

```sql
SELECT 
    type, 
    COUNT(*) AS total_titles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM netflix_staging
GROUP BY type;
```

### 2. Release Seasonality & Content Freshness
Compared the average release year across content types and grouped catalog additions by `MONTH(date_added)` to identify peak months for new releases.

```sql
SELECT MONTH(date_added) AS month_added, COUNT(*) AS titles_added
FROM netflix_staging
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added)
ORDER BY month_added ASC;
```

### 3. Top 3 Maturity Ratings per Category
Used a **CTE and `DENSE_RANK()`** partitioned by `type` to determine the top 3 audience maturity ratings (`TV-MA`, `TV-14`, `R`) separately for Movies and TV Shows.

```sql
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
```

---

## 💡 Key Takeaways
* **Catalog Split:** Movies represent the majority of the catalog by volume, though TV Shows have a more recent average `release_year`, reflecting Netflix's shift toward original serialized content.
* **Audience Focus:** Adult and teen-oriented ratings (`TV-MA` and `TV-14`) dominate both Movies and TV Shows.
* **Production Hubs:** The United States and India lead the platform in total content volume.
