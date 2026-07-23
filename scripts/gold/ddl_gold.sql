/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE gold.dim_customers as
select 
	row_number() over (order by ci.cst_id) as customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as last_name,
	ci.cst_marital_status as marital_status,
	ci.cst_create_date as create_date,
	ca.bdate as birthdate,
	case when ci.cst_gndr != 'n/a' then ci.cst_gndr
	else coalesce(ca.gen, 'n/a')
	end gender,
	la.cntry as country
from silver.crm_cust_info as ci 
left join silver.erp_cust_az12 as ca on ci.cst_key = ca.cid
left join silver.erp_loc_a101 as la on ci.cst_key = la.cid


  

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
  
select * from silver.crm_prd_info
select * from silver.erp_px_cat_g1v2


IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE gold.dim_products as
select 
	row_number() over (order by pn.prd_start_dt, pn.prd_key) as product_key,
	pn.prd_id as product_id,
	pn.prd_key as product_number,
	pn.prd_nm as product_name,
	pn.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance,
	pn.prd_cost as cost,
	pn.prd_line as product_line,
	pn.prd_start_dt as start_date
from silver.crm_prd_info as pn 
left join silver.erp_px_cat_g1v2 as pc on pn.cat_id = pc.id
where prd_end_dt is null



-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
  
select * from silver.crm_sales_details

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE gold.fact_sales as
select 
	sd.sls_ord_num as order_number,
	pr.product_key,
	cu.customer_key,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales_amount,
	sd.sls_quantity as quantity,
	sd.sls_price as price
from silver.crm_sales_details as sd
left join gold.dim_products as pr on sd.sls_prd_key = pr.product_number
left join gold.dim_customers as cu on sd.sls_cust_id = cu.customer_id



  
/* Checking if its all working by joining them */
  
select * from gold.dim_customers
select * from gold.dim_products
select * from gold.fact_sales


select * 
from gold.fact_sales as f
left join gold.dim_customers c on c.customer_key = f.customer_key
left join gold.dim_products p on p.product_key = f.product_key
where p.product_key is null
