/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates the views of the 'gold' schema (the business-ready layer).
    The views follow a star schema: two dimension views and one fact view.

      gold.dim_customers  - customer dimension (CRM + ERP data combined)
      gold.dim_products   - product dimension (CRM + ERP data combined)
      gold.fact_sales     - sales fact, linked to both dimensions by surrogate keys

Layer notes:
    - Gold reads from the Silver layer. No data is stored here; each view runs
      its query when you select from it.
    - Run this script after the Silver layer has been loaded.
    - The views must be created in this order, because gold.fact_sales
      depends on the two dimension views.

Usage:
    SELECT * FROM gold.dim_customers;
    SELECT * FROM gold.dim_products;
    SELECT * FROM gold.fact_sales;
===============================================================================
*/

-- =============================================================================
-- Dimension: Customers
-- Combines CRM customer info with ERP demographics (birthdate, gender)
-- and ERP location (country), one row per customer.
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL    -- 'V' = view
    DROP VIEW gold.dim_customers;                      -- remove old version if it exists
GO

CREATE VIEW gold.dim_customers AS
SELECT
    -- Surrogate key: a generated number used to link the fact table to this dimension
    ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
    ci.cst_id              AS customer_id,
    ci.cst_key             AS customer_number,
    ci.cst_firstname       AS firstname,
    ci.cst_lastname        AS lastname,
    la.CNTRY               AS country,                  -- from ERP location table
    ci.cst_material_status AS marital_status,
    -- CRM is the master source for gender; use ERP only when CRM has no value
    CASE WHEN cst_gndr != 'n/a' THEN cst_gndr
         ELSE COALESCE(GEN, 'n/a')
    END AS gender,
    ca.BDATE               AS birthdate,                -- from ERP demographics table
    ci.cst_create_date     AS create_date
FROM silver.crm_cust_info AS ci
-- LEFT JOINs keep every CRM customer, even without a matching ERP row
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.CID;
GO

-- =============================================================================
-- Dimension: Products
-- Combines CRM product info with ERP categories, one row per product.
-- Only current products are kept (historical versions are filtered out).
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    -- Surrogate key used to link the fact table to this dimension
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.CAT          AS category,                        -- from ERP category table
    pc.SUBCAT       AS subcategory,
    pc.MAINTENANCE,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
FROM silver.crm_prd_info pn
-- LEFT JOIN keeps products even if their category is missing in ERP
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.ID
WHERE prd_end_dt IS NULL;                               -- NULL end date = current version
GO

-- =============================================================================
-- Fact: Sales
-- One row per order line. Uses the surrogate keys of the two dimensions
-- instead of product and customer IDs, following the star schema.
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num   AS order_number,
    pr.product_key,                                     -- foreign key to gold.dim_products
    cu.customer_key,                                    -- foreign key to gold.dim_customers
    sd.sls_order_dt  AS order_date,
    sd.sls_ship_dt   AS ship_date,
    sd.sls_due_dt    AS due_date,
    sd.sls_sales     AS sales_amount,
    sd.sls_quantity  AS quantity,
    sd.sls_price     AS price
FROM silver.crm_sales_details sd
-- Look up the surrogate keys from the dimension views
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO
