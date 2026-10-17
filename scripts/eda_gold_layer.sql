/*
===============================================================================
Exploratory Data Analysis (EDA): Gold Layer
===============================================================================
Purpose:
    Explore the data warehouse built in the previous project to understand the
    database and get the overall business picture.

Tables used (Gold layer, star schema):
    gold.dim_customers  - customer dimension
    gold.dim_products   - product dimension
    gold.fact_sales     - sales transactions

Steps:
    1. Database exploration     - what tables and columns exist
    2. Dimensions exploration   - countries, categories, products
    3. Date exploration         - order date range, youngest and oldest customer
    4. Measures exploration     - the big numbers of the business
    5. Key metrics report       - all main measures in a single result
    6. Magnitude analysis       - totals broken down by dimension
    7. Ranking analysis         - top and bottom performers

Note:
    19 sales rows have no valid order date (see the Issues Log). They are
    included in revenue totals but do not appear in date-based results.
===============================================================================
*/


-- =============================================================================
-- 1. DATABASE EXPLORATION
-- =============================================================================

-- Explore all objects (tables and views) in the database
SELECT * FROM INFORMATION_SCHEMA.Tables;

-- Explore all columns of one table (here: the customer dimension)
SELECT * FROM INFORMATION_SCHEMA.columns
WHERE TABLE_NAME = 'dim_customers';


-- =============================================================================
-- 2. DIMENSIONS EXPLORATION
-- Look at the unique values inside each dimension
-- =============================================================================

-- Explore all the countries our customers come from
SELECT DISTINCT country FROM gold.dim_customers;

-- Explore the product hierarchy: category > subcategory > product
SELECT DISTINCT category, subcategory, product_name FROM gold.dim_products
ORDER BY 1, 2, 3


-- =============================================================================
-- 3. DATE EXPLORATION
-- Understand the time span of the data
-- =============================================================================

-- Find the date of the first and last order,
-- and how many months the business has data for
SELECT
MIN(order_date) AS first_date,
MAX(order_date) AS last_date,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) order_date_range
FROM gold.fact_sales

-- Find the youngest and the oldest customer (and their ages in years)
SELECT
MIN(birthdate) AS  Oldest,
DATEDIFF(year, MIN(birthdate), GETDATE()) oldest_age,
MAX(birthdate) AS youngest,
DATEDIFF(year, MAX(birthdate), GETDATE()) youngest_age
FROM gold.dim_customers


-- =============================================================================
-- 4. MEASURES EXPLORATION
-- The big picture of the business: one number for each key measure
-- =============================================================================

-- Find the total sales (sum of all sales amounts)
SELECT
SUM(sales_amount)
FROM gold.fact_sales;

-- Find how many items were sold
SELECT
SUM(quantity)
FROM gold.fact_sales;

-- Find the average selling price
-- (price is stored as an integer, so it is cast to DECIMAL to keep the decimals)
SELECT
AVG(CAST(price AS DECIMAL(10,2)))
FROM gold.fact_sales;

-- Find the total number of orders
SELECT
COUNT(DISTINCT order_number)
FROM gold.fact_sales;

-- Find the total number of products
SELECT
COUNT(DISTINCT product_name)
FROM gold.dim_products

-- Find the total number of customers
SELECT
COUNT(DISTINCT customer_key)
FROM gold.dim_customers

-- Find the total number of customers who have placed an order
SELECT
COUNT(DISTINCT customer_key)
FROM gold.fact_sales


-- =============================================================================
-- 5. KEY METRICS REPORT
-- Combine all the measures above into one result (UNION ALL stacks the rows)
-- =============================================================================
SELECT 'Total Sales' AS measure_name, SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total Quantity' measure_name, SUM(quantity) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Average price' measure_name, AVG(CAST(price AS DECIMAL(10,2))) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total orders' measure_name, COUNT(DISTINCT order_number) AS measure_value FROM gold.fact_sales
UNION ALL
SELECT 'Total products' measure_name, COUNT(DISTINCT product_name) AS measure_value FROM gold.dim_products
UNION ALL
SELECT 'Total customers' measure_name, COUNT(DISTINCT customer_key) FROM gold.dim_customers
UNION ALL
SELECT 'Total Customer who have orders' measure_name, COUNT(DISTINCT customer_key) FROM gold.fact_sales


-- =============================================================================
-- 6. MAGNITUDE ANALYSIS
-- Compare a measure across a dimension (for example customers by country)
-- =============================================================================

-- Find total customers by country
SELECT
country,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY country
ORDER BY total_customers DESC

-- Find total customers by gender
SELECT
gender,
COUNT(customer_key) AS total_customers
FROM gold.dim_customers
GROUP BY gender
ORDER BY total_customers DESC

-- Find total products by category
SELECT
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC

-- Find the average cost of each category
SELECT
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC

-- What is the total revenue for each category?
-- (the fact table is joined to the product dimension through product_key)
SELECT
p.category,
SUM(s.sales_amount) AS total_revenue
FROM gold.dim_products p
LEFT JOIN gold.fact_sales s
ON p.product_key = s.product_key
GROUP BY p.category
ORDER BY total_revenue DESC

-- What is the total revenue for each customer?
SELECT
f.customer_key,
d.firstname,
d.lastname,
SUM(f.sales_amount) AS customer_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers d
ON f.customer_key = d.customer_key
GROUP BY f.customer_key,d.firstname, d.lastname
ORDER BY customer_revenue DESC

-- What is the distribution of sold items across the countries?
-- (adds up the quantity sold per country)
SELECT
d.country,
SUM(f.quantity) AS distribution_by_country
FROM gold.dim_customers d
LEFT JOIN gold.fact_sales f
ON d.customer_key = f.customer_key
GROUP BY d.country
ORDER BY distribution_by_country DESC


-- =============================================================================
-- 7. RANKING ANALYSIS
-- Order the dimensions by a measure to find the best and worst performers
-- =============================================================================

-- Which 5 products generated the highest revenue?
SELECT TOP 5
d.product_name,
SUM(f.sales_amount) highest_revenue
FROM gold.dim_products d
LEFT JOIN gold.fact_sales f
ON d.product_key = f.product_key
GROUP BY d.product_name
ORDER BY highest_revenue DESC

-- Which 5 products perform the worst?
-- (products with no sales are left out by the IS NOT NULL filter)
SELECT TOP 5
d.product_name,
SUM(f.sales_amount) highest_revenue
FROM gold.dim_products d
LEFT JOIN gold.fact_sales f
ON d.product_key = f.product_key
WHERE f.sales_amount IS NOT NULL
GROUP BY d.product_name
ORDER BY highest_revenue
