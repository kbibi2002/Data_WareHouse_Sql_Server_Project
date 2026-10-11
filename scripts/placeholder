/*
===============================================================================
Stored Procedure: bronze.load_bronze
===============================================================================
Purpose:
    Loads the Bronze layer from the raw source CSV files (full refresh).
    No transformations are applied: data lands exactly as it appears in the files.

    For each table the procedure:
      1. Truncates the Bronze table (removes old data)
      2. Loads the CSV file with BULK INSERT
      3. Prints how long the load took

Sources:
    CRM (3 files): cust_info, prd_info, sales_details
    ERP (3 files): cust_az12, loc_a101, px_cat_g1v2

Usage:
    EXEC bronze.load_bronze;

Notes:
    - BULK INSERT reads files from the machine where SQL Server runs, so the
      file paths below must be reachable by the SQL Server service.
    - Change the file paths to match where the datasets are stored on your PC.
    - TRY...CATCH prints a detailed error report if any step fails.
===============================================================================
*/

-- Full load: empty each table first, then INSERT.
-- A stored procedure lets us reload fresh data with a single command.
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    -- Variables used to measure how long each table (and the whole batch) takes
    DECLARE @start_time DATETIME, @end_time DATETIME,
            @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        -- Start the timer for the whole Bronze load
        SET @batch_start_time = GETDATE();

        -- Print: overall start of the Bronze layer load
        PRINT '=======================================';
        PRINT 'Loading Bronze Layer';
        PRINT '=======================================';

        -- =====================================================================
        -- CRM source tables
        -- =====================================================================
        PRINT '---------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '---------------------------------------';

        -- ---------------------------------------------------------------------
        -- CRM: Customer info
        -- ---------------------------------------------------------------------
        PRINT '=======================================';
        PRINT 'Truncating table: bronze.crm_cust_info';
        PRINT 'Inserting table: bronze.crm_cust_info';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_cust_info;           -- remove old data
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,                              -- skip the header row
            FIELDTERMINATOR = ',',                     -- columns are comma-separated
            TABLOCK                                    -- lock the table for a faster load
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ---------------------------------------------------------------------
        -- CRM: Product info
        -- ---------------------------------------------------------------------
        PRINT '=====================================';
        PRINT 'Truncating table: bronze.crm_prd_info';
        PRINT 'Inserting table: bronze.crm_prd_info';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_prd_info;
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ---------------------------------------------------------------------
        -- CRM: Sales details
        -- ---------------------------------------------------------------------
        PRINT '=======================================';
        PRINT 'Truncating table: bronze.crm_sales_details';
        PRINT 'Inserting table: bronze.crm_sales_details';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.crm_sales_details;
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- =====================================================================
        -- ERP source tables
        -- =====================================================================
        PRINT '---------------------------------------';
        PRINT 'Loading ERP Tables';
        PRINT '---------------------------------------';

        -- ---------------------------------------------------------------------
        -- ERP: Customer demographics (AZ12)
        -- ---------------------------------------------------------------------
        PRINT '=======================================';
        PRINT 'Truncating table: bronze.erp_cust_az12';
        PRINT 'Inserting table: bronze.erp_cust_az12';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_cust_az12;
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ---------------------------------------------------------------------
        -- ERP: Customer location (A101)
        -- ---------------------------------------------------------------------
        PRINT '=======================================';
        PRINT 'Truncating table: bronze.erp_loc_a101';
        PRINT 'Inserting table: bronze.erp_loc_a101';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_loc_a101;
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- ---------------------------------------------------------------------
        -- ERP: Product categories (G1V2)
        -- ---------------------------------------------------------------------
        PRINT '=======================================';
        PRINT 'Truncating table: bronze.erp_px_cat_g1v2';
        PRINT 'Inserting table: bronze.erp_px_cat_g1v2';
        PRINT '=======================================';
        SET @start_time = GETDATE();

        TRUNCATE TABLE bronze.erp_px_cat_g1v2;
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\Abdull\Downloads\sql-data-warehouse-project (1)\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();
        PRINT '>>Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' Seconds';

        -- =====================================================================
        -- Finish: stop the batch timer and print a summary
        -- =====================================================================
        SET @batch_end_time = GETDATE();

        PRINT '=======================================';
        PRINT 'Bronze Layer Load Completed';
        PRINT 'Total Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' Seconds';
        PRINT '=======================================';
    END TRY

    BEGIN CATCH
        -- Error report: runs only if something in the TRY block fails
        PRINT '=======================================';
        PRINT 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
        PRINT '=======================================';
        PRINT 'Error Procedure: ' + ISNULL(ERROR_PROCEDURE(), 'N/A');  -- procedure where the error happened
        PRINT 'Error Message: '   + ERROR_MESSAGE();                   -- what went wrong
        PRINT 'Error Number: '    + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Error Severity: '  + CAST(ERROR_SEVERITY() AS NVARCHAR);
        PRINT 'Error State: '     + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT 'Error Line: '      + CAST(ERROR_LINE() AS NVARCHAR);    -- line number of the failure
        PRINT '=======================================';
    END CATCH
END;
