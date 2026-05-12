/* ============================================================
01_schema.sql - MySQL version for e-commerce dataset
============================================================ */
CREATE DATABASE IF NOT EXISTS ecommerce_project;

USE ecommerce_project;

/* ---------- Staging (raw, all text) ---------- */
DROP TABLE IF EXISTS stg_country_raw;

DROP TABLE IF EXISTS stg_customer_raw;

DROP TABLE IF EXISTS stg_product_raw;

DROP TABLE IF EXISTS stg_sales_raw;

CREATE TABLE stg_country_raw (code VARCHAR(10), name VARCHAR(100));

CREATE TABLE stg_customer_raw (
    id VARCHAR(10),
    name VARCHAR(100),
    gender VARCHAR(10),
    dateofbirth VARCHAR(20),
    email VARCHAR(100),
    country VARCHAR(10),
    city VARCHAR(50),
    created_at VARCHAR(25),
    updated_at VARCHAR(25)
);

CREATE TABLE stg_product_raw (
    id VARCHAR(10),
    name VARCHAR(100),
    code VARCHAR(20),
    category VARCHAR(30),
    price VARCHAR(20),
    currency VARCHAR(10),
    color VARCHAR(30),
    created_at VARCHAR(25),
    updated_at VARCHAR(25)
);

CREATE TABLE stg_sales_raw (
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    sales_date VARCHAR(20),
    quantity VARCHAR(10),
    total_amount VARCHAR(20),
    currency VARCHAR(10),
    created_at VARCHAR(25),
    updated_at VARCHAR(25)
);

/* ---------- Core (clean) ---------- */
DROP TABLE IF EXISTS fct_sales;

DROP TABLE IF EXISTS dim_customer;

DROP TABLE IF EXISTS dim_product;

DROP TABLE IF EXISTS dim_country;

CREATE TABLE dim_country (
    country_code VARCHAR(10) PRIMARY KEY,
    country_name VARCHAR(100)
);

CREATE TABLE dim_customer (
    customer_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    gender VARCHAR(10),
    dateofbirth DATE,
    email VARCHAR(100),
    country_code VARCHAR(10),
    city VARCHAR(50),
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (country_code) REFERENCES dim_country (country_code)
);

CREATE TABLE dim_product (
    product_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(100),
    code VARCHAR(20),
    category VARCHAR(30),
    price DECIMAL(10, 2),
    currency VARCHAR(10),
    color VARCHAR(30),
    created_at DATETIME,
    updated_at DATETIME
);

CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT,
    quarter INT,
    week INT,
    day_of_week INT,
    day_name VARCHAR(20),
    is_weekend INT
);

CREATE TABLE fct_sales (
    sales_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id VARCHAR(10),
    product_id VARCHAR(10),
    sales_date DATE,
    quantity INT,
    total_amount DECIMAL(10, 2),
    currency VARCHAR(10),
    created_at DATETIME,
    updated_at DATETIME,
    FOREIGN KEY (customer_id) REFERENCES dim_customer (customer_id),
    FOREIGN KEY (product_id) REFERENCES dim_product (product_id),
    FOREIGN KEY (sales_date) REFERENCES dim_date (date_id)
);

/* ---------- Audit & Rejection Log ---------- */
DROP TABLE IF EXISTS reject_log;

CREATE TABLE reject_log (
    reject_id INT AUTO_INCREMENT PRIMARY KEY,
    source_table VARCHAR(50),
    source_id VARCHAR(50),
    rejection_reason VARCHAR(255),
    raw_data JSON,
    rejected_at DATETIME DEFAULT CURRENT_TIMESTAMP
);