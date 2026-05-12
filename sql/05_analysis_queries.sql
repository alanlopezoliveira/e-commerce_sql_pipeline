/* ============================================================
   05_analysis_queries.sql - MySQL version for e-commerce dataset
   ============================================================ */

USE ecommerce_project;

-- Q1: Monthly sales evolution (revenue and trends)
SELECT
    m.month_start,
    m.total_revenue,
    m.n_sales,
    m.avg_ticket,
    m.unique_customers,
    LAG(m.total_revenue) OVER (ORDER BY m.month_start) AS prev_month_revenue,
    ROUND(
        (m.total_revenue - LAG(m.total_revenue) OVER (ORDER BY m.month_start)) /
        LAG(m.total_revenue) OVER (ORDER BY m.month_start) * 100, 2
    ) AS revenue_growth_pct,
    SUM(m.total_revenue) OVER (ORDER BY m.month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) / 3 AS moving_avg_3m
FROM vw_monthly_sales_summary m
ORDER BY m.month_start;

-- Q2: Top 5 products by total revenue with market share
SELECT
    product_id,
    product_name,
    SUM(total_revenue) AS total_revenue,
    SUM(total_quantity) AS units_sold,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(
        SUM(total_revenue) / SUM(SUM(total_revenue)) OVER () * 100, 2
    ) AS market_share_pct
FROM vw_sales_enriched
GROUP BY product_id, product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Q3: Top 3 products per month with cumulative rank
SELECT
    month_start,
    product_rank,
    product_id,
    product_name,
    category,
    revenue,
    quantity_sold,
    ROUND(
        revenue / SUM(revenue) OVER (PARTITION BY month_start) * 100, 2
    ) AS share_of_monthly_sales_pct,
    ROUND(
        SUM(revenue) OVER (PARTITION BY product_id ORDER BY month_start),
        2
    ) AS cumulative_product_revenue
FROM vw_top_products_month
WHERE product_rank <= 3
ORDER BY month_start DESC, product_rank;

-- Q4: Customer ranking by monthly spending with cohort
WITH monthly_customers AS (
    SELECT
        DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
        customer_id,
        customer_name,
        SUM(total_amount) AS monthly_revenue,
        RANK() OVER (PARTITION BY DATE_FORMAT(sales_date, '%Y-%m-01') ORDER BY SUM(total_amount) DESC) AS customer_rank
    FROM vw_sales_enriched
    GROUP BY month_start, customer_id, customer_name
)
SELECT
    month_start,
    customer_rank,
    customer_id,
    customer_name,
    monthly_revenue,
    ROUND(
        monthly_revenue / SUM(monthly_revenue) OVER (PARTITION BY month_start) * 100, 2
    ) AS share_of_monthly_spend_pct,
    COUNT(*) OVER (PARTITION BY customer_id ORDER BY month_start ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS purchase_frequency
FROM monthly_customers
WHERE customer_rank <= 3
ORDER BY month_start DESC, customer_rank;

-- Q5: Sales by country and month with YoY comparison
SELECT
    country_name,
    DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
    YEAR(sales_date) AS year,
    MONTH(sales_date) AS month,
    SUM(total_amount) AS monthly_revenue,
    COUNT(DISTINCT customer_id) AS unique_customers,
    LAG(SUM(total_amount)) OVER (PARTITION BY country_name, MONTH(sales_date) ORDER BY YEAR(sales_date)) AS prev_year_revenue
FROM vw_sales_enriched
WHERE country_name IS NOT NULL
GROUP BY country_name, month_start, year, month
ORDER BY country_name, month_start DESC;

-- Q6: Average ticket by product category with percentile ranking
SELECT
    category,
    COUNT(DISTINCT product_id) AS product_count,
    AVG(total_amount) AS avg_ticket,
    ROUND(
        PERCENT_RANK() OVER (ORDER BY AVG(total_amount)) * 100, 2
    ) AS percentile_rank,
    MIN(total_amount) AS min_ticket,
    MAX(total_amount) AS max_ticket,
    STDDEV_POP(total_amount) AS stddev_ticket
FROM vw_sales_enriched
WHERE category IS NOT NULL
GROUP BY category
ORDER BY avg_ticket DESC;

-- Q7: Customers with most purchases and engagement metrics
SELECT
    customer_id,
    customer_name,
    country_name,
    SUM(quantity) AS total_items,
    COUNT(DISTINCT sales_id) AS total_transactions,
    COUNT(DISTINCT DATE_FORMAT(sales_date, '%Y-%m')) AS active_months,
    SUM(total_amount) AS total_spent,
    AVG(total_amount) AS avg_order_value,
    MIN(sales_date) AS first_purchase,
    MAX(sales_date) AS last_purchase,
    DATEDIFF(MAX(sales_date), MIN(sales_date)) AS customer_lifetime_days,
    ROUND(
        SUM(total_amount) / NULLIF(DATEDIFF(MAX(sales_date), MIN(sales_date)), 0) * 30, 2
    ) AS avg_monthly_spend
FROM vw_sales_enriched
GROUP BY customer_id, customer_name, country_name
ORDER BY total_items DESC
LIMIT 5;

-- Q8: Products without sales and inventory gap analysis
SELECT
    p.product_id,
    p.name,
    p.category,
    p.price,
    COALESCE(SUM(s.total_amount), 0) AS total_revenue,
    COALESCE(COUNT(s.sales_id), 0) AS n_sales,
    CASE
        WHEN COUNT(s.sales_id) = 0 THEN 'No Sales'
        WHEN SUM(s.total_amount) < p.price THEN 'Below Cost'
        WHEN COUNT(s.sales_id) < 5 THEN 'Low Engagement'
        ELSE 'Active'
    END AS product_status
FROM
    dim_product p
    LEFT JOIN fct_sales s ON s.product_id = p.product_id
GROUP BY p.product_id, p.name, p.category, p.price
HAVING COUNT(s.sales_id) = 0 OR SUM(s.total_amount) < p.price
ORDER BY p.category;
