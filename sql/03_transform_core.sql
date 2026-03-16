/* ============================================================
03_transform_core.sql - MySQL version for e-commerce dataset
============================================================ */
USE ecommerce_project;

SET
    FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE dim_country;

TRUNCATE TABLE dim_customer;

TRUNCATE TABLE dim_product;

TRUNCATE TABLE fct_sales;

SET
    FOREIGN_KEY_CHECKS = 1;

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