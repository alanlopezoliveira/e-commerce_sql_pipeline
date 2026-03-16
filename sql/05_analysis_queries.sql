/* ============================================================
   05_analysis_queries.sql - MySQL version for e-commerce dataset
   ============================================================ */

USE ecommerce_project;

-- Q1: Monthly sales evolution (revenue)
SELECT * FROM vw_monthly_sales_summary ORDER BY month_start;

-- Q2: Top 5 products by total revenue
SELECT product_id, product_name, SUM(total_amount) AS total_revenue
FROM vw_sales_enriched
GROUP BY product_id, product_name
ORDER BY total_revenue DESC
LIMIT 5;

-- Q3: Top 3 products per month (top-N per group)
SELECT * FROM vw_top_products_month WHERE product_rank <= 3 ORDER BY month_start, product_rank;

-- Q4: Monthly ranking by customer
WITH ranked_customers AS (
  SELECT
    DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
    customer_id,
    customer_name,
    SUM(total_amount) AS revenue,
    RANK() OVER (PARTITION BY DATE_FORMAT(sales_date, '%Y-%m-01') ORDER BY SUM(total_amount) DESC) AS customer_rank
  FROM vw_sales_enriched
  GROUP BY month_start, customer_id, customer_name
)
SELECT * FROM ranked_customers WHERE customer_rank <= 3 ORDER BY month_start, customer_rank;

-- Q5: Sales by country and month
SELECT
  DATE_FORMAT(sales_date, '%Y-%m-01') AS month_start,
  country_name,
  SUM(total_amount) AS revenue
FROM vw_sales_enriched
GROUP BY month_start, country_name
ORDER BY month_start, revenue DESC;

-- Q6: Average ticket by product category
SELECT category, AVG(total_amount) AS avg_ticket
FROM vw_sales_enriched
GROUP BY category;

-- Q7: Customers with most purchases (by quantity)
SELECT customer_id, customer_name, SUM(quantity) AS total_items
FROM vw_sales_enriched
GROUP BY customer_id, customer_name
ORDER BY total_items DESC
LIMIT 5;

-- Q8: Products without sales
SELECT p.product_id, p.name
FROM dim_product p
LEFT JOIN fct_sales s ON s.product_id = p.product_id
WHERE s.product_id IS NULL;
