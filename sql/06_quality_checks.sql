/* ============================================================
06_quality_checks.sql - MySQL version for e-commerce dataset
============================================================ */
USE ecommerce_project;

-- 1) Null keys in core
SELECT
    SUM(
        CASE
            WHEN sales_date IS NULL THEN 1
            ELSE 0
        END
    ) AS null_sales_date,
    SUM(
        CASE
            WHEN customer_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_customer_id,
    SUM(
        CASE
            WHEN product_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_product_id
FROM
    fct_sales;

-- 2) Orphaned foreign keys (there should not be any)
SELECT
    COUNT(*) AS orphan_customer
FROM
    fct_sales f
    LEFT JOIN dim_customer d ON d.customer_id = f.customer_id
WHERE
    d.customer_id IS NULL;

SELECT
    COUNT(*) AS orphan_product
FROM
    fct_sales f
    LEFT JOIN dim_product p ON p.product_id = f.product_id
WHERE
    p.product_id IS NULL;

-- 3) Business duplicates (adjust the key according to your real case)
SELECT
    customer_id,
    product_id,
    sales_date,
    COUNT(*) AS n_dups
FROM
    fct_sales
GROUP BY
    customer_id,
    product_id,
    sales_date
HAVING
    COUNT(*) > 1
ORDER BY
    n_dups DESC;

-- 4) Rango de fechas
SELECT
    MIN(sales_date) AS min_sales_date,
    MAX(sales_date) AS max_sales_date
FROM
    fct_sales;

-- 5) Ventas fuera de rango (ejemplo: total_amount <= 0)
SELECT
    *
FROM
    fct_sales
WHERE
    total_amount <= 0
    OR quantity <= 0;