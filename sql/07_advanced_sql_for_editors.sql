/* ============================================================
   07_advanced_sql_for_editors.sql - MySQL version for e-commerce dataset (SQL editors compatible)
   ============================================================ */

-- NOTE: This script does not use the DELIMITER command.
-- The DELIMITER command is a client-side instruction used by the MySQL CLI to change the statement delimiter,
-- but it is not recognized by the MySQL server or most SQL editors (including DBCode).
-- In DBCode and similar tools, simply end each statement (including procedures, functions, and triggers) with a semicolon (;).
-- This makes the script compatible with DBCode and most SQL editors.

USE ecommerce_project;

/* ---------- Function ---------- */
DROP FUNCTION IF EXISTS fn_safe_pct;
CREATE FUNCTION fn_safe_pct(p_num DECIMAL(14,4), p_den DECIMAL(14,4))
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    IF p_den IS NULL OR p_den = 0 THEN
        RETURN NULL;
    END IF;
    RETURN ROUND(100 * p_num / p_den, 2);
END;

/* ---------- Procedure ---------- */
DROP PROCEDURE IF EXISTS sp_refresh_core;
CREATE PROCEDURE sp_refresh_core()
BEGIN
    DECLARE v_sales_rows BIGINT DEFAULT 0;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error en sp_refresh_core';
    END;
    START TRANSACTION;
    -- Example: TRUNCATE + INSERT a dim/fact from staging
    SET FOREIGN_KEY_CHECKS = 0;
    TRUNCATE TABLE dim_country;
    TRUNCATE TABLE dim_customer;
    TRUNCATE TABLE dim_product;
    TRUNCATE TABLE fct_sales;
    SET FOREIGN_KEY_CHECKS = 1;
    -- Here you could call the INSERTs from 03_transform_core.sql
    SET v_sales_rows = (SELECT COUNT(*) FROM fct_sales);
    COMMIT;
END;

/* ---------- Trigger: Audit sales insertions ---------- */
DROP TABLE IF EXISTS audit_sales_insert;
CREATE TABLE audit_sales_insert (
    audit_id INT AUTO_INCREMENT PRIMARY KEY,
    sales_id INT,
    inserted_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_audit_sales_insert;
CREATE TRIGGER trg_audit_sales_insert
AFTER INSERT ON fct_sales
FOR EACH ROW
BEGIN
    INSERT INTO audit_sales_insert (sales_id) VALUES (NEW.sales_id);
END;

/* ---------- Smoke Test: Basic pipeline check ---------- */
-- This query should return at least one row if pipeline is working
SELECT 'SMOKE TEST PASSED' AS status
FROM fct_sales
WHERE sales_id IS NOT NULL
LIMIT 1;
