# 🎬 Netflix Catalog — Content Strategy & Exploratory Data Analysis (SQL)

## 📌 Project Overview
In this project, I performed an **Exploratory Data Analysis (EDA)** in **MySQL** on the Netflix Movies & TV Shows dataset (`netflix_staging`). The goal was to analyze Netflix's content acquisition strategy by examining the split between Movies and TV Shows, identifying top-producing countries and directors, uncovering monthly release seasonality, and profiling target audience maturity ratings.

🔗 **[View Full SQL Script (`netflix_eda.sql`)](./netflix_eda.sql)**

---

## 🛠️ SQL Skills Demonstrated
* **Database:** MySQL 8.0
* **Key Techniques:**
  * Data Quality & Sanity Checks (`IS NULL`, boundary filtering `release_year > 2026`, `DISTINCT`)
  * Multi-dimensional Aggregations (`COUNT`, `AVG`, `ROUND`, `GROUP BY`)
  * Window Functions for Percentage Share & Ranking (`SUM() OVER()`, `DENSE_RANK() OVER(PARTITION BY ...)`)
  * Common Table Expressions (`WITH` / CTEs)
  * Date Extraction (`MONTH()` for seasonality analysis)

---

## 🔍 Key Analytical Areas

### 1. Data Sanity & Quality Verification
Before running analytical aggregations, I verified the dataset for missing geographical metadata (`country IS NULL`), inspected distinct maturity ratings for unformatted values, and checked for chronological anomalies (`release_year > 2026`).

```sql
SELECT COUNT(*) AS missing_country_count
FROM netflix_staging
WHERE country IS NULL;

SELECT *
FROM netflix_staging
WHERE release_year > 2026;
```

### 2. Catalog Composition (Movies vs. TV Shows)
Calculated both absolute title counts and the relative percentage share of Movies versus TV Shows using a window function.

```sql
SELECT 
    type, 
    COUNT(*) AS total_titles,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM netflix_staging
GROUP BY type;
```

### 3. Geographical Footprint & Top Creators
Identified the leading content-producing countries and ranked the top 10 most prolific directors in the Netflix library.

```sql
SELECT director, COUNT(*) AS total_titles
FROM netflix_staging
WHERE director IS NOT NULL
GROUP BY director
ORDER BY total_titles DESC
LIMIT 10;
```

### 4. Release Seasonality & Content Freshness
Compared the average release year across content types and grouped catalog additions by `MONTH(date_added)` to identify peak months for new releases on the platform.

```sql
SELECT MONTH(date_added) AS month_added, COUNT(*) AS titles_added
FROM netflix_staging
WHERE date_added IS NOT NULL
GROUP BY MONTH(date_added)
ORDER BY month_added ASC;
```

### 5. Target Audience & Top 3 Maturity Ratings per Category
Used a **CTE and `DENSE_RANK()`** partitioned by `type` to determine the top 3 audience maturity ratings (e.g., `TV-MA`, `TV-14`, `R`) separately for Movies and TV Shows.

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
