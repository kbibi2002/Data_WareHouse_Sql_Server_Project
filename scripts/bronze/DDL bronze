/*
===============================================================================
DDL Script: Create Bronze Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' Tables.

Layer notes:
    - Bronze holds the raw data exactly as it comes from the source CSV files.
    - No cleaning or transformation happens here, so column types follow the
      source files (for example, sales dates are stored as integers).
    - Cleaning and standardization are done later, in the Silver layer.

Sources:
    CRM (3 tables): crm_cust_info, crm_prd_info, crm_sales_details
    ERP (3 tables): erp_loc_a101, erp_cust_az12, erp_px_cat_g1v2

WARNING:
    Running this script drops each table first, which deletes all data in it.
    Reload the data afterwards with: EXEC bronze.load_bronze;
===============================================================================
*/

-- =============================================================================
-- CRM: Customer info
-- One row per customer record (can contain duplicates, cleaned in Silver)
-- =============================================================================
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL   -- 'U' = user table
    DROP TABLE bronze.crm_cust_info;                    -- remove old version if it exists
GO

CREATE TABLE bronze.crm_cust_info (
    cst_id              INT,            -- customer ID
    cst_key             NVARCHAR(50),   -- customer business key (links to ERP tables)
    cst_firstname       NVARCHAR(50),
    cst_lastname        NVARCHAR(50),
    cst_marital_status  NVARCHAR(50),   -- coded value, e.g. S / M
    cst_gndr            NVARCHAR(50),   -- coded value, e.g. F / M
    cst_create_date     DATE            -- when the record was created
);
GO

-- =============================================================================
-- CRM: Product info
-- Product history: each row is a product version with a start and end date
-- =============================================================================
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO

CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,                   -- product ID
    prd_key      NVARCHAR(50),          -- combined key: category prefix + product key
    prd_nm       NVARCHAR(50),          -- product name
    prd_cost     INT,
    prd_line     NVARCHAR(50),          -- coded product line, e.g. M / R / S / T
    prd_start_dt DATETIME,              -- version start date
    prd_end_dt   DATETIME               -- version end date (rebuilt in Silver)
);
GO

-- =============================================================================
-- CRM: Sales details
-- Transaction data. Dates arrive as integers (YYYYMMDD), converted in Silver.
-- =============================================================================
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO

CREATE TABLE bronze.crm_sales_details (
    sls_ord_num  NVARCHAR(50),          -- order number
    sls_prd_key  NVARCHAR(50),          -- links to the product key
    sls_cust_id  INT,                   -- links to the customer ID
    sls_order_dt INT,                   -- order date as YYYYMMDD
    sls_ship_dt  INT,                   -- ship date as YYYYMMDD
    sls_due_dt   INT,                   -- due date as YYYYMMDD
    sls_sales    INT,                   -- total sales amount (quantity * price)
    sls_quantity INT,
    sls_price    INT                    -- price per unit
);
GO

-- =============================================================================
-- ERP: Customer location (A101)
-- Country for each customer
-- =============================================================================
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO

CREATE TABLE bronze.erp_loc_a101 (
    cid    NVARCHAR(50),                -- customer ID (contains hyphens, cleaned in Silver)
    cntry  NVARCHAR(50)                 -- country code or name
);
GO

-- =============================================================================
-- ERP: Customer demographics (AZ12)
-- Extra customer details: birthdate and gender
-- =============================================================================
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO

CREATE TABLE bronze.erp_cust_az12 (
    cid    NVARCHAR(50),                -- customer ID (may have a 'NAS' prefix)
    bdate  DATE,                        -- birthdate
    gen    NVARCHAR(50)                 -- gender in mixed formats
);
GO

-- =============================================================================
-- ERP: Product categories (G1V2)
-- Category and subcategory for each product
-- =============================================================================
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO

CREATE TABLE bronze.erp_px_cat_g1v2 (
    id           NVARCHAR(50),          -- category ID (matches cat_id in Silver products)
    cat          NVARCHAR(50),          -- category
    subcat       NVARCHAR(50),          -- subcategory
    maintenance  NVARCHAR(50)           -- maintenance flag (Yes / No)
);
GO
