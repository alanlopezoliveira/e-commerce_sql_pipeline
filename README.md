# E-commerce SQL Pipeline (MySQL)

This project implements a reproducible SQL analytics pipeline for a small e-commerce dataset using **MySQL**. It demonstrates best practices in data modeling, cleaning, analysis, and advanced SQL features.

## Dataset

The project uses four CSV files (see `data/`):

- `country_raw.csv`: Country codes and names (with duplicates)
- `customer_raw.csv`: Customer info (ID, name, gender, birthdate, country, etc.)
- `product_raw.csv`: Product catalog (ID, name, category, price, etc.)
- `sales_raw.csv`: Sales transactions (customer, product, date, quantity, amount, etc.)

## Business Questions

The pipeline is designed to answer key business questions, including:

- How does monthly revenue evolve?
- What are the top products and customers by sales?
- What is the average ticket by product category?
- Which products have no sales?
- How do sales break down by country and month?

See `sql/05_analysis_queries.sql` for all queries.

## Project Structure

- `data/`: Raw CSV files (do not edit)
- `sql/01_schema.sql`: Creates staging, core, and dimension tables (includes dim_date for temporal analysis and reject_log for data quality tracking)
- `sql/02_load_staging.sql`: Data quality checks after CSV import
- `sql/03_transform_core.sql`: Cleans, transforms, and loads data into dimensions and facts; logs rejected records
- `sql/04_semantic_views.sql`: Business views for KPI analysis (customer LTV, product performance, country metrics, category trends)
- `sql/05_analysis_queries.sql`: Advanced analytical queries with window functions, trend analysis, and actionable insights (8+ documented)
- `sql/06_quality_checks.sql`: Data/model quality validation (nulls, orphaned keys, duplicates, date ranges, out-of-range values)
- `sql/07_advanced_sql.sql`: Advanced SQL features (safe percentage function, automated core refresh procedure, sales audit trigger, smoke test)
- `README.md`: This documentation

## How to Reproduce (MySQL)

1. **Create the database and tables:**
	- Run `sql/01_schema.sql` in MySQL Workbench, DBeaver, or CLI.

2. **Import CSVs into staging tables:**
	- Use your SQL client’s CSV import tool to load each file into its corresponding `stg_*` table.

3. **Run data checks:**
	- Execute `sql/02_load_staging.sql` to validate the import and spot quality issues.

4. **Transform and load core tables:**
	- Run `sql/03_transform_core.sql` to clean, transform, and populate dimensions, facts, and rejection log.
	- Alternatively, call the automated procedure: `CALL sp_refresh_core();` (executes all transformations with transaction safety).

5. **Create business views:**
	- Run `sql/04_semantic_views.sql` to create KPI views for customers, products, countries, and categories.

6. **Run quality checks:**
	- Execute `sql/06_quality_checks.sql` to validate nulls, orphaned keys, duplicates, and date ranges.

7. **Run analysis queries:**
	- Use `sql/05_analysis_queries.sql` to answer business questions and uncover trends (revenue growth, top products, customer engagement, YoY comparisons).

8. **Test advanced SQL:**
	- Run `sql/07_advanced_sql.sql` to test the automated refresh procedure, audit trigger, percentage function, and smoke test.

9. **Review rejected records:**
	- Query `reject_log` to understand which records failed transformation and why (data quality traceability).

## Findings & Data Quality

- **Duplicate country codes** were found in `country_raw.csv` (see staging checks).
- Some **customers have missing country codes** or malformed birthdates.
- **Products** and **sales** with invalid or missing numeric fields are filtered out during transformation.
- **Rejected records** are logged in `reject_log` table with reason and raw data for traceability and debugging.
- **Quality checks** (`sql/06_quality_checks.sql`) ensure no nulls in keys, no orphaned foreign keys, and no negative sales.
- **Advanced SQL**: Includes a safe percentage function, a fully automated core refresh procedure (with transaction safety and error handling), a trigger to audit sales insertions, and a smoke test to validate pipeline health.

## Key Insights & Business Value

The pipeline delivers actionable intelligence through:

- **Revenue Trends**: Monthly revenue growth rates, moving averages, and YoY comparisons reveal seasonal patterns and growth momentum.
- **Product Performance**: Top products by revenue, market share, and sales velocity identify high-value and low-performing inventory.
- **Customer Engagement**: Customer lifetime value, purchase frequency, and segment analysis support retention and targeting strategies.
- **Geographic Analysis**: Country and regional breakdowns enable market expansion decisions and localized pricing strategies.
- **Data Quality**: Rejection tracking ensures visibility into data integrity issues, supporting continuous process improvement.
- **Operational Efficiency**: Automated refresh procedure enables daily/weekly transformations with minimal manual intervention.

The model supports BI tool integration (Tableau, Power BI) through semantic views oriented to dashboard requirements.

- The pipeline expects the CSVs to be imported as-is, with all cleaning done in SQL.
- Only MySQL syntax is supported (tested on MySQL 8+).
- Some data issues (e.g., missing country for some customers) are not fixed but flagged.
- The project is designed for clarity and reproducibility, not for large-scale performance.

---
