/* ============================================================
   02_load_staging.sql - MySQL version for e-commerce dataset
   ============================================================ */

USE ecommerce_project;

/* ---------- Volume checks ---------- */
SELECT 'stg_country_raw' AS table_name, COUNT(*) AS n_rows FROM stg_country_raw
UNION ALL
SELECT 'stg_customer_raw', COUNT(*) FROM stg_customer_raw
UNION ALL
SELECT 'stg_product_raw', COUNT(*) FROM stg_product_raw
UNION ALL
SELECT 'stg_sales_raw', COUNT(*) FROM stg_sales_raw;

/* ---------- Samples ---------- */
SELECT * FROM stg_country_raw LIMIT 10;
SELECT * FROM stg_customer_raw LIMIT 10;
SELECT * FROM stg_product_raw LIMIT 10;
SELECT * FROM stg_sales_raw LIMIT 10;

/* ---------- Parsability and quality checks ---------- */
-- country: check for duplicate codes
SELECT code, COUNT(*) as n FROM stg_country_raw GROUP BY code HAVING n > 1;

-- customer: check for nulls and date format
SELECT COUNT(*) AS null_id FROM stg_customer_raw WHERE id IS NULL OR id = '';
SELECT COUNT(*) AS bad_dateofbirth FROM stg_customer_raw WHERE STR_TO_DATE(dateofbirth, '%d.%m.%y') IS NULL AND dateofbirth IS NOT NULL AND dateofbirth != '';

-- product: check for price numeric
SELECT COUNT(*) AS bad_price FROM stg_product_raw WHERE price NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';

-- sales: check for missing/invalid quantity, total_amount, and date
SELECT COUNT(*) AS bad_quantity FROM stg_sales_raw WHERE quantity NOT REGEXP '^[0-9]+$' OR quantity IS NULL OR quantity = '';
SELECT COUNT(*) AS bad_total_amount FROM stg_sales_raw WHERE total_amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' OR total_amount IS NULL OR total_amount = '';
SELECT COUNT(*) AS bad_sales_date FROM stg_sales_raw WHERE STR_TO_DATE(sales_date, '%Y-%m-%d') IS NULL AND sales_date IS NOT NULL AND sales_date != '';