/* ============================================================
03_transform_core.sql - MySQL version for e-commerce dataset
============================================================ */
USE ecommerce_project;

SET
    FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE dim_date;

TRUNCATE TABLE dim_country;

TRUNCATE TABLE dim_customer;

TRUNCATE TABLE dim_product;

TRUNCATE TABLE fct_sales;

TRUNCATE TABLE reject_log;

SET
    FOREIGN_KEY_CHECKS = 1;

/* ---------- Date Dimension ---------- */
-- Populate dim_date from last 1095 days (3 years)
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

/* ---------- Dimensiones ---------- */
-- Country
INSERT INTO
    dim_country (country_code, country_name)
SELECT DISTINCT
    TRIM(code),
    TRIM(name)
FROM
    stg_country_raw
WHERE
    code IS NOT NULL
    AND code != '';

-- Customer
INSERT INTO
    dim_customer (
        customer_id,
        name,
        gender,
        dateofbirth,
        email,
        country_code,
        city,
        created_at,
        updated_at
    )
SELECT
    TRIM(id),
    TRIM(name),
    TRIM(gender),
    STR_TO_DATE(dateofbirth, '%d.%m.%y'),
    TRIM(email),
    NULLIF(TRIM(country), ''),
    TRIM(city),
    STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
FROM
    stg_customer_raw
WHERE
    id IS NOT NULL
    AND id != ''
    AND (
        STR_TO_DATE(dateofbirth, '%d.%m.%y') IS NOT NULL
        OR dateofbirth IS NULL
        OR dateofbirth = ''
    );

-- Product
INSERT INTO
    dim_product (
        product_id,
        name,
        code,
        category,
        price,
        currency,
        color,
        created_at,
        updated_at
    )
SELECT
    TRIM(id),
    TRIM(name),
    TRIM(code),
    TRIM(category),
    CAST(price AS DECIMAL(10, 2)),
    TRIM(currency),
    TRIM(color),
    STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
FROM
    stg_product_raw
WHERE
    id IS NOT NULL
    AND id != ''
    AND price REGEXP '^[0-9]+(\\.[0-9]+)?$';

/* ---------- Fact ---------- */
INSERT INTO
    fct_sales (
        customer_id,
        product_id,
        sales_date,
        quantity,
        total_amount,
        currency,
        created_at,
        updated_at
    )
SELECT
    TRIM(customer_id),
    TRIM(product_id),
    STR_TO_DATE(sales_date, '%Y-%m-%d'),
    CAST(quantity AS UNSIGNED),
    CAST(total_amount AS DECIMAL(10, 2)),
    TRIM(currency),
    STR_TO_DATE(created_at, '%Y-%m-%d %H:%i:%s'),
    STR_TO_DATE(updated_at, '%Y-%m-%d %H:%i:%s')
FROM
    stg_sales_raw
WHERE
    customer_id IS NOT NULL
    AND customer_id != ''
    AND product_id IS NOT NULL
    AND product_id != ''
    AND STR_TO_DATE(sales_date, '%Y-%m-%d') IS NOT NULL
    AND quantity REGEXP '^[0-9]+$'
    AND total_amount REGEXP '^[0-9]+(\\.[0-9]+)?$';

/* ---------- Rejection Log ---------- */
-- Log rejected sales records
INSERT INTO reject_log (source_table, source_id, rejection_reason, raw_data)
SELECT
    'stg_sales_raw' AS source_table,
    CONCAT(customer_id, '_', product_id, '_', sales_date) AS source_id,
    CASE
        WHEN customer_id IS NULL OR customer_id = '' THEN 'Missing customer_id'
        WHEN product_id IS NULL OR product_id = '' THEN 'Missing product_id'
        WHEN STR_TO_DATE(sales_date, '%Y-%m-%d') IS NULL THEN 'Invalid sales_date format'
        WHEN quantity NOT REGEXP '^[0-9]+$' THEN 'Invalid quantity (non-numeric)'
        WHEN total_amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$' THEN 'Invalid total_amount (non-numeric)'
    END AS rejection_reason,
    JSON_OBJECT(
        'customer_id', customer_id,
        'product_id', product_id,
        'sales_date', sales_date,
        'quantity', quantity,
        'total_amount', total_amount
    ) AS raw_data
FROM stg_sales_raw
WHERE
    customer_id IS NULL OR customer_id = ''
    OR product_id IS NULL OR product_id = ''
    OR STR_TO_DATE(sales_date, '%Y-%m-%d') IS NULL
    OR quantity NOT REGEXP '^[0-9]+$'
    OR total_amount NOT REGEXP '^[0-9]+(\\.[0-9]+)?$';