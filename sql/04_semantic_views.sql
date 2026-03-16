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
    co.country_name
FROM
    fct_sales s
    JOIN dim_customer c ON c.customer_id = s.customer_id
    JOIN dim_product p ON p.product_id = s.product_id
    LEFT JOIN dim_country co ON co.country_code = c.country_code;

-- Monthly sales summary
CREATE OR REPLACE VIEW vw_monthly_sales_summary AS
SELECT
    DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
    COUNT(*) AS n_sales,
    SUM(total_amount) AS total_revenue,
    AVG(total_amount) AS avg_ticket
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
    SUM(s.total_amount) AS revenue,
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
    p.name;