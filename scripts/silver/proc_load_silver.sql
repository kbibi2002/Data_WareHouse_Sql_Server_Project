/*
===============================================================================
Stored Procedure: silver.load_silver
===============================================================================
Purpose:
    Loads the Silver layer from the Bronze layer (full refresh).
    For each table it:
      1. Truncates the Silver table
      2. Inserts cleaned and standardized data from Bronze

Sources : CRM (3 tables), ERP (3 tables)
Usage   : EXEC silver.load_silver;
===============================================================================
*/
Create OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;

	BEGIN TRY
	set @batch_start_time = GETDATE();
    -- Print: overall start of the silver layer load
	Print'=======================================';
	Print'Loading silver Layer';
	Print'=======================================';

	-- Print: section header for CRM source tables
	Print'---------------------------------------';
	Print'Loading CRM Tables';
	Print'---------------------------------------';

	Print'=======================================';
	Print'Truncating table: silver.crm_cust_info';
	Print'Inserting table: silver.crm_cust_info';
	Print'=======================================';
		set @start_time = GETDATE();

    -- =========================================================================
    -- CRM: Customer info
    -- Cleaning: trim names, decode gender / marital status, keep latest record
    -- =========================================================================
    TRUNCATE TABLE silver.crm_cust_info;

    INSERT INTO silver.crm_cust_info (
        cst_id, cst_key, cst_firstname, cst_lastname,
        cst_gndr, cst_material_status, cst_create_date
    )
    SELECT
        cst_id,
        cst_key,
        TRIM(cst_firstname) AS cst_firstname,              -- remove extra spaces
        TRIM(cst_lastname)  AS cst_lastname,
        -- Standardize gender codes to readable values
        CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
             WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
             ELSE 'n/a'
        END AS cst_gndr,
        -- Standardize marital status codes
        CASE WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
             WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Merried'
             ELSE 'n/a'
        END AS cst_material_status,
        cst_create_date
    FROM (
        -- Deduplicate: rank records per customer, newest first
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
        FROM bronze.crm_cust_info
    ) t
    WHERE flag_last = 1 AND cst_id IS NOT NULL;                                   -- keep only the latest record
    	set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
	

    -- =========================================================================
    -- CRM: Product info
    -- Cleaning: split product key, default null cost, decode product line,
    --           derive end date from the next version's start date
    -- =========================================================================
    Print'=====================================';
		Print'Truncating table: silver.crm_prd_info';
		Print'Inserting table: silver.crm_prd_info';
		Print'=======================================';
		set @start_time = GETDATE();
    TRUNCATE TABLE silver.crm_prd_info;

    INSERT INTO silver.crm_prd_info (
        prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
    )
    SELECT
        prd_id,
        REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,     -- category ID (first 5 chars)
        SUBSTRING(prd_key, 7, LEN(prd_key))         AS prd_key,    -- actual product key
        TRIM(prd_nm)                                AS prd_nm,
        ISNULL(prd_cost, 0)                         AS prd_cost,   -- null cost becomes 0
        -- Decode product line abbreviations
        CASE UPPER(TRIM(prd_line))
            WHEN 'M' THEN 'Mountain'
            WHEN 'R' THEN 'Road'
            WHEN 'S' THEN 'Other Sales'
            WHEN 'T' THEN 'Touring'
            ELSE 'n/a'
        END AS prd_line,
        CAST(prd_start_dt AS DATE) AS prd_start_dt,
        -- End date = day before the next version starts (null for current version)
        CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt) - 1 AS DATE) AS prd_end_dt
    FROM bronze.crm_prd_info;
set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
	
		

    -- =========================================================================
    -- CRM: Sales details
    -- Cleaning: convert integer dates (YYYYMMDD) to DATE,
    --           recalculate invalid sales / price values
    -- =========================================================================
    -- Print: truncating and inserting silver.crm_sales_details
		Print'=======================================';
		Print'Truncating table: silver.crm_sales_details';
		Print'Inserting table: silver.crm_sales_details';
		Print'=======================================';
		set @start_time = GETDATE();
    TRUNCATE TABLE silver.crm_sales_details;

    INSERT INTO silver.crm_sales_details (
        sls_ord_num, sls_prd_key, sls_cust_id,
        sls_order_dt, sls_ship_dt, sls_due_dt,
        sls_sales, sls_quantity, sls_price
    )
    SELECT
        sls_ord_num,
        sls_prd_key,
        sls_cust_id,
        -- Invalid dates (wrong length or <= 0) become NULL
        CASE WHEN LEN(sls_order_dt) != 8 OR sls_order_dt <= 0
             THEN NULL
             ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)   -- NOTE: references sls_ship_dt, check (see notes)
        END AS sls_order_dt,
        CASE WHEN LEN(sls_ship_dt) != 8 OR sls_ship_dt <= 0
             THEN NULL
             ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
        END AS sls_ship_dt,
        CASE WHEN LEN(sls_due_dt) != 8 OR sls_due_dt <= 0
             THEN NULL
             ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)   -- NOTE: references sls_ship_dt, check (see notes)
        END AS sls_due_dt,
        -- Sales should equal quantity * price; recalculate if missing, negative or inconsistent
        CASE WHEN sls_sales != sls_quantity * ABS(sls_price) OR sls_sales <= 0 OR sls_sales IS NULL
             THEN sls_quantity * ABS(sls_price)
             ELSE sls_sales
        END AS sls_sales,
        sls_quantity,
        -- Derive price from sales / quantity if price is missing or invalid
        CASE WHEN sls_price IS NULL OR sls_price <= 0
             THEN sls_sales / NULLIF(sls_quantity, 0)          -- NULLIF avoids divide-by-zero
             ELSE sls_price
        END AS sls_price
    FROM bronze.crm_sales_details;
    set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';

    -- =========================================================================
    -- ERP: Customer demographics (AZ12)
    -- Cleaning: strip 'NAS' prefix from ID, null out future birthdates,
    --           standardize gender
    -- =========================================================================
    Print'---------------------------------------';
		Print'Loading ERP Tables';
		Print'---------------------------------------';
        Print'=======================================';
		Print'Truncating table: silver.erp_cust_az12';
		Print'Inserting table: silver.erp_cust_az12';
		Print'=======================================';
		set @start_time = GETDATE();
    TRUNCATE TABLE silver.erp_cust_az12;

    INSERT INTO silver.erp_cust_az12 (CID, BDATE, GEN)
    SELECT
        -- Remove 'NAS' prefix so IDs match the CRM customer key
        CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
             ELSE CID
        END AS CID,
        -- Birthdates in the future are invalid
        CASE WHEN BDATE > GETDATE() THEN NULL
             ELSE BDATE
        END AS BDATE,
        -- Normalize gender values
        CASE WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'FEMALE'
             WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE')   THEN 'MALE'
             ELSE 'n/a'
        END AS GEN
    FROM bronze.erp_cust_az12;
    set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';

    -- =========================================================================
    -- ERP: Customer location (A101)
    -- Cleaning: remove hyphens from ID, standardize country names
    -- =========================================================================
    -- Print: truncating and inserting silver.erp_loc_a101
		Print'=======================================';
		Print'Truncating table: silver.erp_loc_a101';
		Print'Inserting table: silver.erp_loc_a101';
		Print'=======================================';
		set @start_time = GETDATE();
    TRUNCATE TABLE silver.erp_loc_a101;

    INSERT INTO silver.erp_loc_a101 (CID, CNTRY)
    SELECT
        REPLACE(CID, '-', '') AS CID,                          -- match CRM customer key format
        -- Normalize country codes; blanks / nulls become 'n/a'
        CASE WHEN TRIM(CNTRY) = 'DE'             THEN 'Germany'
             WHEN TRIM(CNTRY) IN ('US', 'USA')   THEN 'United States'
             WHEN TRIM(CNTRY) = '' OR CNTRY IS NULL THEN 'n/a'
             ELSE CNTRY
        END AS CNTRY
    FROM bronze.erp_loc_a101;
    set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
	
    
    -- =========================================================================
    -- ERP: Product categories (G1V2)
    -- No transformation needed; data is loaded as-is
    -- =========================================================================
    Print'=======================================';
		Print'Truncating table: silver.erp_px_cat_g1v2';
		Print'Inserting table: silver.erp_px_cat_g1v2';
		Print'=======================================';
		set @start_time = GETDATE();
    TRUNCATE TABLE silver.erp_px_cat_g1v2;

    INSERT INTO silver.erp_px_cat_g1v2 (ID, CAT, SUBCAT, MAINTENANCE)
    SELECT ID, CAT, SUBCAT, MAINTENANCE
    FROM bronze.erp_px_cat_g1v2;
    set @end_time = GETDATE();
		Print'>>Load Duration: ' + Cast(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'Seconds';
		set @batch_end_time = GETDATE();
        Print'=======================================';
	Print'Silver Layer Load Completed';
	Print'Total Duration: ' + cast(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'Seconds';
	Print'=======================================';
	END TRY
	BEGIN CATCH
	-- Print: error report, runs only if something in the TRY block fails
		Print'=======================================';
		Print'ERROR OCCURRED DURING LOADING SILVER LAYER';
		Print'=======================================';
		Print'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');
		Print'Error Message: '   + ERROR_MESSAGE();
		Print'Error Number: '    + CAST(ERROR_NUMBER() AS NVARCHAR);
		Print'Error Severity: '  + CAST(ERROR_SEVERITY() AS NVARCHAR);
		Print'Error State: '     + CAST(ERROR_STATE() AS NVARCHAR);
		Print'Error Line: '      + CAST(ERROR_LINE() AS NVARCHAR);
		Print'=======================================';
	END CATCH
END
