/*
===============================================================================
DDL Script: Create Silver Tables
===============================================================================
Script Purpose:
    This script creates tables in the 'silver' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'silver' Tables.

Layer notes:
    - Silver holds cleaned and standardized data loaded from the Bronze layer.
    - Column types are final: dates are real DATE values (not integers) and
      codes are decoded into readable values by silver.load_silver.
    - Every table has an extra audit column, dwh_create_date, that records
      when each row was loaded into the warehouse.

Sources:
    CRM (3 tables): crm_cust_info, crm_prd_info, crm_sales_details
    ERP (3 tables): erp_cust_az12, erp_loc_a101, erp_px_cat_g1v2

WARNING:
    Running this script drops each table first, which deletes all data in it.
    Reload the data afterwards with: EXEC silver.load_silver;
===============================================================================
*/

-- =============================================================================
-- CRM: Customer info
-- One row per customer (duplicates removed in the load procedure)
-- =============================================================================
IF OBJECT_ID('silver.crm_cust_info', 'U') IS NOT NULL   -- 'U' = user table
    DROP TABLE silver.crm_cust_info;                    -- remove old version if it exists
GO

CREATE TABLE silver.crm_cust_info (
    cst_id               INT,            -- customer ID
    cst_key              NVARCHAR(50),   -- customer business key (links to ERP tables)
    cst_firstname        NVARCHAR(50),   -- trimmed first name
    cst_lastname         NVARCHAR(50),   -- trimmed last name
    cst_material_status  NVARCHAR(50),   -- decoded marital status (Single / Married / n/a)
    cst_gndr             NVARCHAR(50),   -- decoded gender (Female / Male / n/a)
    cst_create_date      DATE,           -- when the record was created in the source
    dwh_create_date      DATETIME2 DEFAULT GETDATE()   -- load timestamp (filled automatically)
);
GO

-- =============================================================================
-- CRM: Product info
-- Product history: each row is a product version with a start and end date
-- =============================================================================
IF OBJECT_ID('silver.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE silver.crm_prd_info;
GO

CREATE TABLE silver.crm_prd_info (
    prd_id           INT,                -- product ID
    cat_id           NVARCHAR(50),       -- category ID taken from the start of the product key
    prd_key          NVARCHAR(50),       -- product key without the category prefix
    prd_nm           NVARCHAR(50),       -- product name
    prd_cost         INT,                -- cost (null values replaced with 0)
    prd_line         NVARCHAR(50),       -- decoded product line (Mountain / Road / ...)
    prd_start_dt     DATE,               -- version start date
    prd_end_dt       DATE,               -- version end date (derived from the next version's start)
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================================================
-- CRM: Sales details
-- Transaction data with integer dates converted to DATE
-- =============================================================================
IF OBJECT_ID('silver.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE silver.crm_sales_details;
GO

CREATE TABLE silver.crm_sales_details (
    sls_ord_num      NVARCHAR(50),       -- order number
    sls_prd_key      NVARCHAR(50),       -- links to the product key
    sls_cust_id      INT,                -- links to the customer ID
    sls_order_dt     DATE,               -- order date (converted from YYYYMMDD)
    sls_ship_dt      DATE,               -- ship date
    sls_due_dt       DATE,               -- due date
    sls_sales        INT,                -- total sales (recalculated if invalid)
    sls_quantity     INT,
    sls_price        INT,                -- price per unit (derived if missing)
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================================================
-- ERP: Customer demographics (AZ12)
-- Extra customer details: birthdate and gender
-- =============================================================================
IF OBJECT_ID('silver.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE silver.erp_cust_az12;
GO

CREATE TABLE silver.erp_cust_az12 (
    CID              NVARCHAR(50),       -- customer ID (the 'NAS' prefix removed)
    BDATE            DATE,               -- birthdate (future dates set to NULL)
    GEN              NVARCHAR(50),       -- standardized gender (FEMALE / MALE / n/a)
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================================================
-- ERP: Customer location (A101)
-- Country for each customer
-- =============================================================================
IF OBJECT_ID('silver.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE silver.erp_loc_a101;
GO

CREATE TABLE silver.erp_loc_a101 (
    CID              NVARCHAR(50),       -- customer ID (hyphens removed to match the CRM key)
    CNTRY            VARCHAR(50),        -- standardized country name
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO

-- =============================================================================
-- ERP: Product categories (G1V2)
-- Category and subcategory for each product (loaded as-is)
-- =============================================================================
IF OBJECT_ID('silver.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE silver.erp_px_cat_g1v2;
GO

CREATE TABLE silver.erp_px_cat_g1v2 (
    ID               NVARCHAR(50),       -- category ID (matches cat_id in crm_prd_info)
    CAT              NVARCHAR(50),       -- category
    SUBCAT           NVARCHAR(50),       -- subcategory
    MAINTENANCE      NVARCHAR(50),       -- maintenance flag (Yes / No)
    dwh_create_date  DATETIME2 DEFAULT GETDATE()
);
GO
