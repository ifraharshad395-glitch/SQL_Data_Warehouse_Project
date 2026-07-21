/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME;
	BEGIN TRY
			SET @batch_start_time = GETDATE();
			PRINT '============================================';
			PRINT 'Loading Silver Layer';
			PRINT '============================================';

			PRINT '--------------------------------------------';
			PRINT ' Loading CRM Tables';
			PRINT '--------------------------------------------';


		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT '>> Inserting Data into silver.crm_cust_info';
		INSERT INTO silver.crm_cust_info (
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		select 
		cst_id,
		cst_key,
		trim(cst_firstname) as cst_firstname,
		trim(cst_lastname) as cst_lastname,
		case when upper(trim(cst_marital_status)) = 'S' then 'Single'
			 when upper(trim(cst_marital_status)) = 'M' then 'Married'
		else 'n/a'
		end cst_marital_status,
		case when upper(trim(cst_gndr)) = 'F' then 'Female'
			 when upper(trim(cst_gndr)) = 'M' then 'Male'
		else 'n/a'
		end cst_gndr,
		cst_create_date
		from (
		select *,
		row_number() over (partition by cst_id order by cst_create_date desc) as flag_last 
		from bronze.crm_cust_info ) t
		where flag_last = 1;
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';




		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.crm_prd_info';
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT '>> Inserting Data into silver.crm_prd_info';
		INSERT INTO silver.crm_prd_info (
			prd_id,
			prd_key,
			cat_id,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)

		select 
		prd_id,
		replace(substring(prd_key, 1, 5), '-', '_') as cat_id,
		substring(prd_key, 7, len(prd_key)) as prd_key,
		prd_nm,
		isnull(prd_cost, 0) as prd_cost,
		case upper(trim(prd_line))
			 when  'M' then 'Mountain'
			 when  'R' then 'Road'
			 when  'S' then 'Other Sales'
			 when  'T' then 'Touring'
		else 'n/a' 
		end prd_line,
		cast(prd_start_dt as date) as prd_start_dt,
		cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt) - 1  as date) as prd_end_dt
		from bronze.crm_prd_info
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';




		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT '>> Inserting Data into silver.crm_sales_details';
		INSERT INTO silver.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
		)

		select 
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then null 
			else cast(cast(sls_order_dt as varchar) as date) 
		end sls_order_dt,
		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then null 
			else cast(cast(sls_ship_dt as varchar) as date) 
		end sls_ship_dt,
		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then null 
			else cast(cast(sls_due_dt as varchar) as date) 
		end sls_due_dt,
		case when sls_sales is null or sls_sales <= 0 or sls_sales!= sls_quantity * abs(sls_price)  then sls_quantity * abs(sls_price)	
			else sls_sales
		end sls_sales,
		sls_quantity,
		case when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity, 0) 
			else sls_price 
		end sls_price
		from bronze.crm_sales_details
 			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';




		PRINT '--------------------------------------------';
		PRINT ' Loading ERP Tables';
		PRINT '--------------------------------------------';

		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.erp_cust_az12';
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT '>> Inserting Data into silver.erp_cust_az12';
		INSERT INTO silver.erp_cust_az12 (
			cid,
			bdate,
			gen
		)

		select 
		case when cid like 'NAS%' then substring(cid, 4, len(cid)) 
			else cid
		end cid,
		case when bdate > getdate() then null 
			else bdate 
		end bdate,
		case when upper(trim(gen)) in ('F', 'Female') then 'Female'
			 when upper(trim(gen)) in ('M', 'Male') then 'Male'
			else 'n/a' 
		end gen
		from bronze.erp_cust_az12
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';






		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.erp_loc_a101';
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT '>> Inserting Data into silver.erp_loc_a101';
		INSERT INTO silver.erp_loc_a101 (
			cid,
			cntry
		)

		select 
		replace(cid, '-', '') as cid, 
		case when trim(cntry) = 'DE' then 'Germany'
			 when trim(cntry) in ('US', 'USA') then 'United States' 
			 when trim(cntry) = '' or trim(cntry) is null then 'n/a' 
			else trim(cntry)
		end cntry
		from bronze.erp_loc_a101
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';





		SET @start_time = GETDATE();
		PRINT '>> Truncating Table silver.erp_px_cat_g1v2';
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT '>> Inserting Data into silver.erp_px_cat_g1v2';
		INSERT INTO silver.erp_px_cat_g1v2 (
			id,
			cat,
			subcat,
			maintenance
		)

		select
		id,
		cat,
		subcat,
		maintenance
		from bronze.erp_px_cat_g1v2
			SET @end_time = GETDATE();
			PRINT '>> Load Duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' seconds';

	END TRY
		BEGIN CATCH
		PRINT '=====================';
		PRINT 'ERROR OCCURED WHILE LOADING SILVER LAYER';
		PRINT '=====================';
	END CATCH
END
