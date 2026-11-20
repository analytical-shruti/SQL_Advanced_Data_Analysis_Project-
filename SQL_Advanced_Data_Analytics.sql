/*
================================================================
PROJECT : SQL ADVANCED DATA ANALYTICS
DATABASE: MySQL 8.0+  (CTEs and window functions need 8.0)
SCHEMA  : gold  (fact_sales, dim_customers, dim_products)

CONTENTS
  00. Optional setup (create tables + load CSVs)
  PART 1  - EDA
     01 Database Exploration     02 Dimensions Exploration
     03 Date Exploration         04 Measures / KPIs
     05 Magnitude Analysis       06 Ranking Analysis
     07 Practice Variations      08 Data Validation
  PART 2  - ADVANCED ANALYTICS
     09 Changes Over Time        10 Cumulative Analysis
     11 Performance Analysis     12 Part-to-Whole Analysis
     13 Data Segmentation
  PART 3  - FINAL REPORTS (VIEWS)
     14 Customer Report          15 Product Report

All numbers quoted in the comments were re-verified against the
three CSV files (60,398 sales rows / 18,484 customers / 295 products).
================================================================
*/


/*
================================================================
00. OPTIONAL SETUP - run only if the tables do not exist yet
    (If you already imported with MySQL Workbench's Table Data
     Import Wizard, skip this block.)
    LOAD DATA LOCAL needs:  SET GLOBAL local_infile = 1;
    Empty CSV cells are converted to NULL with NULLIF().
    Change the file paths to your own folder.
================================================================
*/

CREATE DATABASE IF NOT EXISTS gold;
USE gold;

CREATE TABLE IF NOT EXISTS dim_customers (
    customer_key    INT PRIMARY KEY,
    customer_id     INT,
    customer_number VARCHAR(20),
    first_name      VARCHAR(50),
    last_name       VARCHAR(50),
    country         VARCHAR(50),
    marital_status  VARCHAR(20),
    gender          VARCHAR(20),
    birthdate       DATE,
    create_date     DATE
);

CREATE TABLE IF NOT EXISTS dim_products (
    product_key    INT PRIMARY KEY,
    product_id     INT,
    product_number VARCHAR(50),
    product_name   VARCHAR(100),
    category_id    VARCHAR(20),
    category       VARCHAR(50),
    subcategory    VARCHAR(50),
    maintenance    VARCHAR(10),
    cost           INT,
    product_line   VARCHAR(30),
    start_date     DATE
);

CREATE TABLE IF NOT EXISTS fact_sales (
    order_number  VARCHAR(20),
    product_key   INT,
    customer_key  INT,
    order_date    DATE,
    shipping_date DATE,
    due_date      DATE,
    sales_amount  INT,
    quantity      INT,
    price         INT
);

/* -- Uncomment and edit the paths to load the data --

LOAD DATA LOCAL INFILE 'C:/path/gold_dim_customers.csv'
INTO TABLE dim_customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(customer_key, customer_id, customer_number, first_name, last_name,
 @country, marital_status, @gender, @birthdate, create_date)
SET country   = NULLIF(@country, ''),
    gender    = NULLIF(@gender, ''),
    birthdate = NULLIF(@birthdate, '');

LOAD DATA LOCAL INFILE 'C:/path/gold_dim_products.csv'
INTO TABLE dim_products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_key, product_id, product_number, product_name, @category_id,
 @category, @subcategory, @maintenance, cost, @product_line, start_date)
SET category_id  = NULLIF(@category_id, ''),
    category     = NULLIF(@category, ''),
    subcategory  = NULLIF(@subcategory, ''),
    maintenance  = NULLIF(@maintenance, ''),
    product_line = NULLIF(@product_line, '');

LOAD DATA LOCAL INFILE 'C:/path/gold_fact_sales.csv'
INTO TABLE fact_sales
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_number, product_key, customer_key, @order_date, shipping_date,
 due_date, sales_amount, quantity, price)
SET order_date = NULLIF(@order_date, '');

*/

USE gold;


/*
================================================================
PART 1 - EXPLORATORY DATA ANALYSIS (EDA)
================================================================
*/

/* =========================================================
   01. DATABASE EXPLORATION
   ========================================================= */

-- Q1. What tables and views exist in the database?
SELECT
    TABLE_SCHEMA AS database_name,
    TABLE_NAME   AS object_name,
    TABLE_TYPE   AS object_type
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_SCHEMA, TABLE_NAME;


-- Q2. What columns exist in the database?
SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    ORDINAL_POSITION,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
ORDER BY TABLE_SCHEMA, TABLE_NAME, ORDINAL_POSITION;


-- Q3. What columns are present in the customer dimension?
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    ORDINAL_POSITION
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'gold'
  AND TABLE_NAME = 'dim_customers'
ORDER BY ORDINAL_POSITION;


/* =========================================================
   02. DIMENSIONS EXPLORATION
   ========================================================= */

-- Q4. Which countries do customers come from?
SELECT DISTINCT country
FROM gold.dim_customers
ORDER BY country;
-- Note: 337 customers have a NULL country.


-- Q5. Which product categories exist?
SELECT DISTINCT category
FROM gold.dim_products
ORDER BY category;
-- Result: Accessories, Bikes, Clothing (+ NULL for 7 products).


-- Q6. What category > subcategory > product hierarchy exists?
SELECT DISTINCT
    category,
    subcategory,
    product_name
FROM gold.dim_products
ORDER BY category, subcategory, product_name;


/* =========================================================
   03. DATE EXPLORATION
   ========================================================= */

-- Q7. What are the first and last order dates?
SELECT
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date
FROM gold.fact_sales;
-- Verified: 2010-12-29 to 2014-01-28.


-- Q8. How many years and months of order history are available?
SELECT
    TIMESTAMPDIFF(YEAR,  MIN(order_date), MAX(order_date)) AS order_range_years,
    TIMESTAMPDIFF(MONTH, MIN(order_date), MAX(order_date)) AS order_range_months
FROM gold.fact_sales;
-- TIMESTAMPDIFF gives exact full years/months elapsed.


-- Q9. Oldest and youngest customers (by birthdate)?
SELECT
    MIN(birthdate) AS oldest_birthdate,
    MAX(birthdate) AS youngest_birthdate
FROM gold.dim_customers;


-- Q10. Oldest and youngest customers' ages?
SELECT
    TIMESTAMPDIFF(YEAR, MIN(birthdate), CURDATE()) AS oldest_age,
    TIMESTAMPDIFF(YEAR, MAX(birthdate), CURDATE()) AS youngest_age
FROM gold.dim_customers;
-- Age depends on the date you run it (CURDATE()).


/* =========================================================
   04. MEASURES EXPLORATION / BUSINESS KPIs
   ========================================================= */

-- Q11. Total sales revenue
SELECT SUM(sales_amount) AS total_sales
FROM gold.fact_sales;
-- Verified: 29,356,250


-- Q12. Total items sold
SELECT SUM(quantity) AS total_quantity
FROM gold.fact_sales;
-- Verified: 60,423


-- Q13. Average selling price
SELECT AVG(price) AS average_price
FROM gold.fact_sales;
-- Verified: about 486.04


-- Q14. Number of sales rows (order lines)
SELECT COUNT(order_number) AS sales_rows
FROM gold.fact_sales;
-- Verified: 60,398 (an order can appear on several rows)


-- Q15. Number of unique orders
SELECT COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales;
-- Verified: 27,659


-- Q16. Products in the product dimension
SELECT COUNT(product_key) AS total_products
FROM gold.dim_products;
-- Verified: 295


-- Q17. Registered customers
SELECT COUNT(customer_key) AS total_customers
FROM gold.dim_customers;
-- Verified: 18,484


-- Q18. Distinct customers who placed an order
SELECT COUNT(DISTINCT customer_key) AS customers_who_ordered
FROM gold.fact_sales;
-- Verified: 18,484


-- Q19. Consolidated KPI report (UNION ALL)
SELECT 'Total Sales'            AS measure_name, SUM(sales_amount)            AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity',         SUM(quantity)                                FROM gold.fact_sales
UNION ALL
SELECT 'Average Price',          AVG(price)                                   FROM gold.fact_sales
UNION ALL
SELECT 'Order Lines (count)',    COUNT(order_number)                          FROM gold.fact_sales
UNION ALL
SELECT 'Unique Orders',          COUNT(DISTINCT order_number)                 FROM gold.fact_sales
UNION ALL
SELECT 'Total Products',         COUNT(product_key)                           FROM gold.dim_products
UNION ALL
SELECT 'Total Customers',        COUNT(customer_key)                          FROM gold.dim_customers
UNION ALL
SELECT 'Customers Who Ordered',  COUNT(DISTINCT customer_key)                 FROM gold.fact_sales;


/* =========================================================
   05. MAGNITUDE ANALYSIS (measure by dimension)
   ========================================================= */

-- Q20. Customers by country
SELECT
    country,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC;


-- Q21. Customers by gender
SELECT
    gender,
    COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC;


-- Q22. Products by category
SELECT
    category,
    COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC;


-- Q23. Average product cost by category
SELECT
    category,
    AVG(cost) AS average_cost
FROM gold.dim_products
GROUP BY category
ORDER BY average_cost DESC;


-- Q24. Total revenue by product category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_revenue DESC;
-- Verified: Bikes 28,316,272 | Accessories 700,262 | Clothing 339,716


-- Q25. Total revenue by customer
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC;


-- Q26. Items sold by country
SELECT
    c.country,
    SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC;


/* =========================================================
   06. RANKING ANALYSIS
   ========================================================= */

-- Q27. Which 5 products generated the HIGHEST revenue?
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 5;
-- Verified output:
-- Mountain-200 Black- 46      1,373,454
-- Mountain-200 Black- 42      1,363,128
-- Mountain-200 Silver- 38     1,339,394
-- Mountain-200 Silver- 46     1,301,029
-- Mountain-200 Black- 38      1,294,854


-- Q28. Which 5 products generated the LOWEST revenue?
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_revenue ASC
LIMIT 5;
-- Verified output:
-- Racing Socks- L             2,430
-- Racing Socks- M             2,682
-- Patch Kit/8 Patches         6,382
-- Bike Wash - Dissolver       7,272
-- Touring Tire Tube           7,440


-- Q29. Subcategories with the highest revenue
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_revenue DESC;
-- Verified top 5: Road Bikes 14,519,438 | Mountain Bikes 9,952,254 |
--   Touring Bikes 3,844,580 | Tires and Tubes 244,634 | Helmets 225,435


-- Q30. Subcategories with the lowest revenue
SELECT
    p.subcategory,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.subcategory
ORDER BY total_revenue ASC;
-- Verified bottom 5: Socks 5,112 | Cleaners 7,272 | Caps 19,710 |
--   Gloves 34,320 | Vests 36,160


-- Q31. Top 5 products by revenue using ROW_NUMBER()
SELECT *
FROM
(
    SELECT
        p.product_name,
        SUM(f.sales_amount) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    GROUP BY p.product_name
) AS ranked_products
WHERE rank_products <= 5
ORDER BY rank_products;
-- Same five products as Q27.


-- Q32. Top 10 customers by revenue
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_revenue DESC, c.customer_key
LIMIT 10;
-- Verified output (customer_key, name, revenue):
-- 1302 Nichole Nara        13,294
-- 1133 Kaitlyn Henderson   13,294
-- 1309 Margaret He         13,268
-- 1132 Randall Dominguez   13,265
-- 1301 Adriana Gonzalez    13,242
-- 1322 Rosa Hu             13,215
-- 1125 Brandi Gill         13,195
-- 1308 Brad She            13,172
-- 1297 Francisco Sara      13,164
--  434 Maurice Shan        12,914


-- Q33. 3 customers with the fewest unique orders
-- 11,619 customers have exactly 1 order, so a tie-breaker is needed
-- to make the output reproducible.
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders ASC, c.customer_key ASC
LIMIT 3;
-- Verified output:
-- 16 Chloe Young    1
-- 17 Wyatt Hill     1
-- 21 Jordan King    1


/* =========================================================
   07. PRACTICE VARIATIONS
   ========================================================= */

-- Q34. Revenue by country
SELECT
    c.country,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC;


-- Q35. Total orders by country
SELECT
    c.country,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_orders DESC;


-- Q36. Average selling price by product
SELECT
    p.product_name,
    AVG(f.price) AS average_selling_price
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY average_selling_price DESC;


-- Q37. Quantity sold by product category
SELECT
    p.category,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_quantity DESC;


-- Q38. Unique customers by product category
SELECT
    p.category,
    COUNT(DISTINCT f.customer_key) AS unique_customers
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY unique_customers DESC;


-- Q39. Top 5 countries by revenue
SELECT
    c.country,
    SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.country
ORDER BY total_revenue DESC
LIMIT 5;


-- Q40. Top 5 customers by number of unique orders
SELECT
    c.customer_key,
    c.first_name,
    c.last_name,
    COUNT(DISTINCT f.order_number) AS total_orders
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
GROUP BY c.customer_key, c.first_name, c.last_name
ORDER BY total_orders DESC, c.customer_key
LIMIT 5;


/* =========================================================
   08. DATA VALIDATION / JOIN CHECKS
   Verified from the CSV files: all four checks return 0 rows/0.
   ========================================================= */

-- Fact rows with no matching product
SELECT COUNT(*) AS unmatched_product_rows
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_products AS p
    ON f.product_key = p.product_key
WHERE p.product_key IS NULL;

-- Fact rows with no matching customer
SELECT COUNT(*) AS unmatched_customer_rows
FROM gold.fact_sales AS f
LEFT JOIN gold.dim_customers AS c
    ON f.customer_key = c.customer_key
WHERE c.customer_key IS NULL;

-- Duplicate product keys
SELECT product_key, COUNT(*) AS duplicate_count
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1;

-- Duplicate customer keys
SELECT customer_key, COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Data-quality note: 19 sales rows (sales_amount total 4,992) have a
-- NULL order_date. Time-based analysis filters them out; Q11 and the
-- category totals (Q24 / Part-to-Whole) include them.


/*
================================================================
PART 2 - ADVANCED SQL DATA ANALYTICS
================================================================
*/

/*===============================================================
09. CHANGES OVER TIME ANALYSIS
===============================================================*/

-- Q41. Monthly sales, customers and quantity (YEAR / MONTH)
SELECT
    YEAR(order_date)  AS order_year,
    MONTH(order_date) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY YEAR(order_date), MONTH(order_date)
ORDER BY YEAR(order_date), MONTH(order_date);


-- Q42. Same analysis, month as the first day of the month
-- (MySQL has no DATETRUNC, so DATE_FORMAT is used)
SELECT
    CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE) AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE)
ORDER BY CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE);


-- Q43. Same analysis, text month label ('2013-Jan')
-- DATE_FORMAT returns text, so ORDER BY the label would sort
-- alphabetically. Ordering by MIN(order_date) keeps it chronological.
SELECT
    DATE_FORMAT(order_date, '%Y-%b') AS order_month,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customers,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATE_FORMAT(order_date, '%Y-%b')
ORDER BY MIN(order_date);


-- Q44. Yearly sales and year-over-year growth
-- Verified results:
--   2010:     43,419   (only a few days of data)
--   2011:  7,075,088
--   2012:  5,842,231   (-17.43% vs 2011)
--   2013: 16,344,878   (+179.77% vs 2012)  <-- $16.34M
--   2014:     45,642   (data ends 2014-01-28)
WITH yearly_sales AS
(
    SELECT
        YEAR(order_date)  AS order_year,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY YEAR(order_date)
)
SELECT
    order_year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY order_year) AS previous_year_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY order_year)) * 100.0
        / NULLIF(LAG(total_sales) OVER (ORDER BY order_year), 0),
        2
    ) AS yoy_growth_pct
FROM yearly_sales
ORDER BY order_year;


/*===============================================================
10. CUMULATIVE ANALYSIS
===============================================================*/

-- Q45. Monthly sales + running total that restarts every year
SELECT
    order_month,
    total_sales,
    SUM(total_sales) OVER (
        PARTITION BY YEAR(order_month)
        ORDER BY order_month
    ) AS running_total_sales
FROM
(
    SELECT
        CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE) AS order_month,
        SUM(sales_amount) AS total_sales
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY CAST(DATE_FORMAT(order_date, '%Y-%m-01') AS DATE)
) AS monthly_sales
ORDER BY order_month;


-- Q46. Yearly sales, running total across years, moving average price
SELECT
    order_year,
    total_sales,
    SUM(total_sales) OVER (ORDER BY order_year) AS running_total_sales,
    AVG(avg_price)   OVER (ORDER BY order_year) AS moving_average_price
FROM
(
    SELECT
        MAKEDATE(YEAR(order_date), 1) AS order_year,
        SUM(sales_amount) AS total_sales,
        AVG(price) AS avg_price
    FROM gold.fact_sales
    WHERE order_date IS NOT NULL
    GROUP BY MAKEDATE(YEAR(order_date), 1)
) AS yearly_sales
ORDER BY order_year;


/*===============================================================
11. PERFORMANCE ANALYSIS
===============================================================*/

-- Q47. Yearly product sales vs the product's average and vs previous year
WITH yearly_product_sales AS
(
    SELECT
        YEAR(f.order_date) AS order_year,
        p.product_name,
        SUM(f.sales_amount) AS current_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
    GROUP BY YEAR(f.order_date), p.product_name
)
SELECT
    order_year,
    product_name,
    current_sales,

    AVG(current_sales) OVER (PARTITION BY product_name) AS avg_sales,
    current_sales
        - AVG(current_sales) OVER (PARTITION BY product_name) AS diff_avg,

    CASE
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) > 0 THEN 'Above Avg'
        WHEN current_sales - AVG(current_sales) OVER (PARTITION BY product_name) < 0 THEN 'Below Avg'
        ELSE 'Avg'
    END AS avg_change,

    LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS previous_year_sales,
    current_sales
        - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_previous_year,

    CASE
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
        WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS year_over_year_change

FROM yearly_product_sales
ORDER BY product_name, order_year;


/*===============================================================
12. PART-TO-WHOLE ANALYSIS
===============================================================*/

-- Q48. Contribution of each category to total sales
-- Verified: Bikes 28,316,272 = 96.46% | Accessories 700,262 = 2.39% |
--           Clothing 339,716 = 1.16%   (overall 29,356,250)
WITH category_sales AS
(
    SELECT
        p.category,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON p.product_key = f.product_key
    GROUP BY p.category
)
SELECT
    category,
    total_sales,
    SUM(total_sales) OVER () AS overall_sales,
    ROUND(total_sales * 100.0 / SUM(total_sales) OVER (), 2) AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC;


/*===============================================================
13. DATA SEGMENTATION
===============================================================*/

-- Q49. Products by cost range
-- (No product has a cost of exactly 100, 500 or 1000, so the
--  boundaries below do not change the counts.)
-- Verified: Below 100 = 110 | 100-500 = 101 | 500-1000 = 45 | Above 1000 = 39
WITH product_segments AS
(
    SELECT
        product_key,
        product_name,
        cost,
        CASE
            WHEN cost < 100   THEN 'Below 100'
            WHEN cost <= 500  THEN '100-500'
            WHEN cost <= 1000 THEN '500-1000'
            ELSE 'Above 1000'
        END AS cost_range
    FROM gold.dim_products
)
SELECT
    cost_range,
    COUNT(product_key) AS total_products
FROM product_segments
GROUP BY cost_range
ORDER BY total_products DESC;


-- Q50. Customer segments by spending and lifespan
--   VIP     : lifespan >= 12 months AND total spending > 5000
--   Regular : lifespan >= 12 months AND total spending <= 5000
--   New     : lifespan <  12 months
-- Verified: New 14,629 | Regular 2,200 | VIP 1,653
--   (18,482 customers; 2 customers only have rows with a NULL order_date)
WITH customer_spending AS
(
    SELECT
        c.customer_key,
        SUM(f.sales_amount) AS total_spending,
        MIN(f.order_date)   AS first_order,
        MAX(f.order_date)   AS last_order,
        (YEAR(MAX(f.order_date)) - YEAR(MIN(f.order_date))) * 12
            + MONTH(MAX(f.order_date)) - MONTH(MIN(f.order_date)) AS lifespan
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON f.customer_key = c.customer_key
    WHERE f.order_date IS NOT NULL
    GROUP BY c.customer_key
),
segmented_customers AS
(
    SELECT
        customer_key,
        CASE
            WHEN lifespan >= 12 AND total_spending > 5000  THEN 'VIP'
            WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
            ELSE 'New'
        END AS customer_segment
    FROM customer_spending
)
SELECT
    customer_segment,
    COUNT(customer_key) AS total_customers
FROM segmented_customers
GROUP BY customer_segment
ORDER BY total_customers DESC;


/*
================================================================
PART 3 - FINAL REPORTS (REUSABLE VIEWS)
================================================================
*/

/*===============================================================
14. CUSTOMER REPORT  ->  gold.report_customers
    Purpose: key customer metrics and behaviours
      1. Names, age, age group
      2. Segments: VIP / Regular / New
      3. Aggregates: orders, sales, quantity, products, lifespan
      4. KPIs: recency, average order value, average monthly spend
===============================================================*/

DROP VIEW IF EXISTS gold.report_customers;

CREATE VIEW gold.report_customers AS
WITH base_query AS
(
    SELECT
        f.order_number,
        f.product_key,
        f.order_date,
        f.sales_amount,
        f.quantity,
        c.customer_key,
        c.customer_number,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        TIMESTAMPDIFF(YEAR, c.birthdate, CURDATE()) AS age
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_customers AS c
        ON c.customer_key = f.customer_key
    WHERE f.order_date IS NOT NULL
),
customer_aggregation AS
(
    SELECT
        customer_key,
        customer_number,
        customer_name,
        age,
        COUNT(DISTINCT order_number) AS total_orders,
        SUM(sales_amount)            AS total_sales,
        SUM(quantity)                AS total_quantity,
        COUNT(DISTINCT product_key)  AS total_products,
        MAX(order_date)              AS last_order_date,
        (YEAR(MAX(order_date)) - YEAR(MIN(order_date))) * 12
            + MONTH(MAX(order_date)) - MONTH(MIN(order_date)) AS lifespan
    FROM base_query
    GROUP BY customer_key, customer_number, customer_name, age
)
SELECT
    customer_key,
    customer_number,
    customer_name,
    age,
    CASE
        WHEN age IS NULL           THEN 'n/a'
        WHEN age < 20              THEN 'Under 20'
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50 and above'
    END AS age_group,
    CASE
        WHEN lifespan >= 12 AND total_sales > 5000  THEN 'VIP'
        WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
        ELSE 'New'
    END AS customer_segment,
    last_order_date,
    (YEAR(CURDATE()) - YEAR(last_order_date)) * 12
        + MONTH(CURDATE()) - MONTH(last_order_date) AS recency,
    total_orders,
    total_sales,
    total_quantity,
    total_products,
    lifespan,
    -- Average order value
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE CAST(total_sales AS DECIMAL(18,2)) / total_orders
    END AS avg_order_value,
    -- Average monthly spend
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE CAST(total_sales AS DECIMAL(18,2)) / lifespan
    END AS avg_monthly_spend
FROM customer_aggregation;


-- View the customer report
SELECT * FROM gold.report_customers;


-- Customers by segment
-- Verified: New 14,629 customers / 11,086,797 sales
--           VIP  1,653 customers / 10,760,470 sales
--           Regular 2,200 customers / 7,503,991 sales
SELECT
    customer_segment,
    COUNT(*)          AS total_customers,
    SUM(total_sales)  AS total_sales,
    AVG(total_sales)  AS avg_sales_per_customer
FROM gold.report_customers
GROUP BY customer_segment
ORDER BY total_sales DESC;


-- Customers by age group
SELECT
    age_group,
    COUNT(*)         AS total_customers,
    SUM(total_sales) AS total_sales
FROM gold.report_customers
GROUP BY age_group
ORDER BY total_sales DESC;


/*===============================================================
15. PRODUCT REPORT  ->  gold.report_products
    Purpose: key product metrics and behaviours
      1. Category, subcategory, cost
      2. Segments: High-Performer / Mid-Range / Low-Performer
      3. Aggregates: orders, sales, quantity, customers, lifespan
      4. KPIs: recency, average selling price,
               average order revenue, average monthly revenue
===============================================================*/

DROP VIEW IF EXISTS gold.report_products;

CREATE VIEW gold.report_products AS
WITH base_query AS
(
    SELECT
        f.order_number,
        f.order_date,
        f.customer_key,
        f.sales_amount,
        f.quantity,
        p.product_key,
        p.product_name,
        p.category,
        p.subcategory,
        p.cost
    FROM gold.fact_sales AS f
    LEFT JOIN gold.dim_products AS p
        ON f.product_key = p.product_key
    WHERE f.order_date IS NOT NULL
),
product_aggregations AS
(
    SELECT
        product_key,
        product_name,
        category,
        subcategory,
        cost,
        (YEAR(MAX(order_date)) - YEAR(MIN(order_date))) * 12
            + MONTH(MAX(order_date)) - MONTH(MIN(order_date)) AS lifespan,
        MAX(order_date)                  AS last_sale_date,
        COUNT(DISTINCT order_number)     AS total_orders,
        COUNT(DISTINCT customer_key)     AS total_customers,
        SUM(sales_amount)                AS total_sales,
        SUM(quantity)                    AS total_quantity,
        ROUND(AVG(sales_amount / NULLIF(quantity, 0)), 1) AS avg_selling_price
    FROM base_query
    GROUP BY product_key, product_name, category, subcategory, cost
)
SELECT
    product_key,
    product_name,
    category,
    subcategory,
    cost,
    last_sale_date,
    (YEAR(CURDATE()) - YEAR(last_sale_date)) * 12
        + MONTH(CURDATE()) - MONTH(last_sale_date) AS recency_in_months,
    CASE
        WHEN total_sales > 50000  THEN 'High-Performer'
        WHEN total_sales >= 10000 THEN 'Mid-Range'
        ELSE 'Low-Performer'
    END AS product_segment,
    lifespan,
    total_orders,
    total_sales,
    total_quantity,
    total_customers,
    avg_selling_price,
    -- Average order revenue
    CASE
        WHEN total_orders = 0 THEN 0
        ELSE CAST(total_sales AS DECIMAL(18,2)) / total_orders
    END AS avg_order_revenue,
    -- Average monthly revenue
    CASE
        WHEN lifespan = 0 THEN total_sales
        ELSE CAST(total_sales AS DECIMAL(18,2)) / lifespan
    END AS avg_monthly_revenue
FROM product_aggregations;


-- View the product report
-- (130 products have dated sales; 165 of the 295 products never sold)
SELECT * FROM gold.report_products;


-- Products by performance segment
-- Verified: High-Performer 66 | Mid-Range 58 | Low-Performer 6
SELECT
    product_segment,
    COUNT(*)         AS total_products,
    SUM(total_sales) AS total_sales,
    AVG(total_sales) AS avg_sales_per_product
FROM gold.report_products
GROUP BY product_segment
ORDER BY total_sales DESC;


-- Products by category
SELECT
    category,
    COUNT(*)            AS total_products,
    SUM(total_sales)    AS total_sales,
    SUM(total_quantity) AS total_quantity
FROM gold.report_products
GROUP BY category
ORDER BY total_sales DESC;


-- Products by subcategory
SELECT
    subcategory,
    COUNT(*)            AS total_products,
    SUM(total_sales)    AS total_sales,
    SUM(total_quantity) AS total_quantity
FROM gold.report_products
GROUP BY subcategory
ORDER BY total_sales DESC;


/*
================================================================
END OF PROJECT: SQL ADVANCED DATA ANALYTICS
================================================================
*/
