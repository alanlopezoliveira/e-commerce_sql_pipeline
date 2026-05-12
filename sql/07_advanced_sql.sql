/* ============================================================
   07_advanced_sql.sql - MySQL version for e-commerce dataset (ORIGINAL)
   ============================================================ */

USE ecommerce_project;

/* ---------- Function ---------- */
DELIMITER $$
DROP FUNCTION IF EXISTS fn_safe_pct$$
CREATE FUNCTION fn_safe_pct(p_num DECIMAL(14,4), p_den DECIMAL(14,4))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF p_den IS NULL OR p_den = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(100 * p_num / p_den, 2);
END$$
DELIMITER ;

/* ---------- Procedure ---------- */
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_refresh_core$$
CREATE PROCEDURE sp_refresh_core()
BEGIN
    DECLARE v_countries_inserted BIGINT DEFAULT 0;
    DECLARE v_customers_inserted BIGINT DEFAULT 0;
    DECLARE v_products_inserted BIGINT DEFAULT 0;
    DECLARE v_sales_inserted BIGINT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error in sp_refresh_core: check staging data and constraints';
    END;
    START TRANSACTION;
    
    SET FOREIGN_KEY_CHECKS = 0;
    
    -- Truncate all core tables
    TRUNCATE TABLE dim_date;
    TRUNCATE TABLE dim_country;
    TRUNCATE TABLE dim_customer;
    TRUNCATE TABLE dim_product;
    TRUNCATE TABLE fct_sales;
    TRUNCATE TABLE reject_log;
    
    SET FOREIGN_KEY_CHECKS = 1;
    
    -- Populate date dimension
    INSERT INTO dim_date (date_id, year, month, day, quarter, week, day_of_week, day_name, is_weekend)
    SELECT
        DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY) AS date_id,
        YEAR(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS year,
        MONTH(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS month,
        DAY(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS day,
        QUARTER(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS quarter,
        WEEK(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS week,
        DAYOFWEEK(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS day_of_week,
        DAYNAME(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) AS day_name,
        IF(DAYOFWEEK(DATE_SUB(CURDATE(), INTERVAL (d1.num * 100 + d2.num * 10 + d3.num) DAY)) IN (1, 7), 1, 0) AS is_weekend
    FROM (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d1
    CROSS JOIN (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d2
    CROSS JOIN (SELECT 0 AS num UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) d3
    WHERE (d1.num * 100 + d2.num * 10 + d3.num) < 1095;
    
    -- Populate countries
    INSERT INTO dim_country (country_code, country_name)
    SELECT DISTINCT
        TRIM(code),
        TRIM(name)
    FROM stg_country_raw
    WHERE code IS NOT NULL AND code != '';
    SET v_countries_inserted = ROW_COUNT();
    
    -- Populate customers
    INSERT INTO dim_customer (customer_id, name, gender, dateofbirth, email, country_code, city, created_at, updated_at)
    SELECT
        TRIM(id), TRIM(name), TRIM(gender),
        STR_TO_DATE(dateofbirth, '%d.%m.%y'),
        TRIM(email), NULLIF(TRIM(country), ''), TRIM(city),
        STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
    FROM stg_customer_raw
    WHERE id IS NOT NULL AND id != ''
        AND (STR_TO_DATE(dateofbirth, '%d.%m.%y') IS NOT NULL OR dateofbirth IS NULL OR dateofbirth = '');
    SET v_customers_inserted = ROW_COUNT();
    
    -- Populate products
    INSERT INTO dim_product (product_id, name, code, category, price, currency, color, created_at, updated_at)
    SELECT
        TRIM(id), TRIM(name), TRIM(code), TRIM(category),
        CAST(price AS DECIMAL(10, 2)), TRIM(currency), TRIM(color),
        STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
    FROM stg_product_raw
    WHERE id IS NOT NULL AND id != '' AND price REGEXP '^[0-9]+(\\.[0-9]+)?$';
    SET v_products_inserted = ROW_COUNT();
    
    -- Populate sales fact table
    INSERT INTO fct_sales (customer_id, product_id, sales_date, quantity, total_amount, currency, created_at, updated_at)
    SELECT
        TRIM(customer_id), TRIM(product_id),
        STR_TO_DATE(sales_date, '%Y-%m-%d'),
        CAST(quantity AS UNSIGNED),
        CAST(total_amount AS DECIMAL(10, 2)),
        TRIM(currency),
        STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
        STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
    FROM stg_sales_raw
    WHERE customer_id IS NOT NULL AND customer_id != ''
        AND product_id IS NOT NULL AND product_id != ''
        AND STR_TO_DATE(sales_date, '%Y-%m-%d') IS NOT NULL
        AND quantity REGEXP '^[0-9]+$'
        AND total_amount REGEXP '^[0-9]+(\\.[0-9]+)?$';
    SET v_sales_inserted = ROW_COUNT();
    
    -- Log rejected records
    INSERT INTO reject_log (source_table, source_id, rejection_reason, raw_data)
    SELECT
        'stg_sales_raw', CONCAT(customer_id, '_', product_id, '_', sales_date),
        CASE
            WHEN customer_id IS NULL OR customer_id = '' THEN 'Missing customer_id'
            WHEN product_id IS NULL OR product_id = '' THEN 'Missing product_id'
            WHEN STR_TO_DATE(sales_date, '%Y-%m-%d') IS NULL THEN 'Invalid sales_date format'
            WHEN quantity NOT REGEXP '^[0-9]+$' THEN 'Invalid quantity'
            WHEN total_amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 'Invalid total_amount'
        END,
        JSON_OBJECT('customer_id', customer_id, 'product_id', product_id, 'sales_date', sales_date, 'quantity', quantity, 'total_amount', total_amount)
    FROM stg_sales_raw
    WHERE customer_id IS NULL OR customer_id = ''
        OR product_id IS NULL OR product_id = ''
        OR STR_TO_DATE(sales_date, '%Y-%m-%d') IS NULL
        OR quantity NOT REGEXP '^[0-9]+$'
        OR total_amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';
    
    COMMIT;
    
    SELECT CONCAT('Core refresh completed: ', v_countries_inserted, ' countries, ',
                  v_customers_inserted, ' customers, ', v_products_inserted, ' products, ',
                  v_sales_inserted, ' sales') AS refresh_summary;
END$$
DELIMITER ;

/* ---------- Trigger: Audit sales insertions ---------- */
DROP TABLE IF EXISTS audit_sales_insert;
CREATE TABLE audit_sales_insert (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    sales_id INT,
    inserted_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_audit_sales_insert;
DELIMITER $$
CREATE TRIGGER trg_audit_sales_insert
AFTER INSERT ON fct_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_sales_insert (sales_id) VALUES (NEW.sales_id);
END$$
DELIMITER ;

/* ---------- Smoke Test: Basic pipeline check ---------- */
-- This query should return at least one row if pipeline is working
SELECT 'SMOKE TEST PASSED' AS status
FROM fct_sales
WHERE sales_id IS NOT NULL
LIMIT 1;
