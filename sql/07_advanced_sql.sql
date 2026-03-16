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
