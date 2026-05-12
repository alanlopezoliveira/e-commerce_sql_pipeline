/* ============================================================
04_semantic_views.sql - MySQL version for e-commerce dataset
============================================================ */
USE ecommerce_project;

-- Enriched sales view
CREATE OR REPLACE VIEW vw_sales_enriched AS
SELECT
    s.sales_id,
    s.sales_date,
    s.quantity,
    s.total_amount,
    s.currency,
    s.created_at,
    s.updated_at,
    c.customer_id,
    c.name AS customer_name,
    c.gender,
    c.dateofbirth,
    c.country_code,
    c.city,
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    p.color,
    co.country_name,
    d.year,
    d.month,
    d.quarter
FROM
    fct_sales s
    JOIN dim_customer c ON c.customer_id = s.customer_id
    JOIN dim_product p ON p.product_id = s.product_id
    LEFT JOIN dim_country co ON co.country_code = c.country_code
    LEFT JOIN dim_date d ON d.date_id = s.sales_date;

-- Monthly sales summary
CREATE OR REPLACE VIEW vw_monthly_sales_summary AS
SELECT
    DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
    COUNT(*) AS n_sales,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_ticket,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM
    fct_sales
GROUP BY
    month_start;

-- Top products by revenue per month
CREATE OR REPLACE VIEW vw_top_products_month AS
SELECT
    DATE_FORMAT(s.sales_date, '%Y-%m-01') AS month_start,
    p.product_id,
    p.name AS product_name,
    p.category,
    SUM(s.total_amount) AS revenue,
    SUM(s.quantity) AS quantity_sold,
    COUNT(*) AS n_transactions,
    RANK() OVER (
        PARTITION BY
            DATE_FORMAT(s.sales_date, '%Y-%m-01')
        ORDER BY
            SUM(s.total_amount) DESC
    ) AS product_rank
FROM
    fct_sales s
    JOIN dim_product p ON p.product_id = s.product_id
GROUP BY
    month_start,
    p.product_id,
    p.name,
    p.category;

-- Customer lifetime value and engagement
CREATE OR REPLACE VIEW vw_customer_kpi AS
SELECT
    c.customer_id,
    c.name AS customer_name,
    c.country_code,
    COUNT(DISTINCT s.sales_id) AS total_purchases,
    SUM(s.total_amount) AS lifetime_revenue,
    AVG(s.total_amount) AS avg_order_value,
    MIN(s.sales_date) AS first_purchase_date,
    MAX(s.sales_date) AS last_purchase_date,
    DATEDIFF(MAX(s.sales_date), MIN(s.sales_date)) AS days_active,
    COUNT(DISTINCT DATE_FORMAT(s.sales_date, '%Y-%m')) AS months_active
FROM
    dim_customer c
    LEFT JOIN fct_sales s ON s.customer_id = c.customer_id
GROUP BY
    c.customer_id,
    c.name,
    c.country_code;

-- Product performance and popularity
CREATE OR REPLACE VIEW vw_product_kpi AS
SELECT
    p.product_id,
    p.name AS product_name,
    p.category,
    p.price,
    COUNT(DISTINCT s.sales_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue,
    SUM(s.quantity) AS total_quantity,
    AVG(s.total_amount) AS avg_sale_amount,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM
    dim_product p
    LEFT JOIN fct_sales s ON s.product_id = p.product_id
GROUP BY
    p.product_id,
    p.name,
    p.category,
    p.price;

-- Country and regional performance
CREATE OR REPLACE VIEW vw_country_kpi AS
SELECT
    co.country_code,
    co.country_name,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT s.sales_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_ticket,
    SUM(s.quantity) AS total_quantity
FROM
    dim_country co
    LEFT JOIN dim_customer c ON c.country_code = co.country_code
    LEFT JOIN fct_sales s ON s.customer_id = c.customer_id
GROUP BY
    co.country_code,
    co.country_name;

-- Category performance summary
CREATE OR REPLACE VIEW vw_category_kpi AS
SELECT
    p.category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT s.sales_id) AS total_sales,
    SUM(s.total_amount) AS total_revenue,
    AVG(s.total_amount) AS avg_ticket,
    SUM(s.quantity) AS total_quantity,
    COUNT(DISTINCT s.customer_id) AS unique_customers
FROM
    dim_product p
    LEFT JOIN fct_sales s ON s.product_id = p.product_id
GROUP BY
    p.category;