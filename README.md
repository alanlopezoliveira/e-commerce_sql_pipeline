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
- `sql/01_schema.sql`: Creates all staging and core tables
- `sql/02_load_staging.sql`: Data quality checks after CSV import
- `sql/03_transform_core.sql`: Cleans and loads data into core tables
- `sql/04_semantic_views.sql`: Business views for analysis
- `sql/05_analysis_queries.sql`: Analytical queries (8+ documented)
- `sql/06_quality_checks.sql`: Data/model quality checks
- `sql/07_advanced_sql.sql`: Advanced SQL (function, procedure, trigger, smoke test)
- `README.md`: This documentation

## How to Reproduce (MySQL)

1. **Create the database and tables:**
	- Run `sql/01_schema.sql` in MySQL Workbench, DBeaver, or CLI.

2. **Import CSVs into staging tables:**
	- Use your SQL client’s CSV import tool to load each file into its corresponding `stg_*` table.

3. **Run data checks:**
	- Execute `sql/02_load_staging.sql` to validate the import and spot issues.

4. **Transform and load core tables:**
	- Run `sql/03_transform_core.sql` to clean and populate dimensions and fact tables.

5. **Create business views:**
	- Run `sql/04_semantic_views.sql`.

6. **Run quality checks:**
	- Execute `sql/06_quality_checks.sql` to check for nulls, orphans, duplicates, and out-of-range values.

7. **Run analysis queries:**
	- Use `sql/05_analysis_queries.sql` to answer business questions.

8. **Test advanced SQL:**
	- Run `sql/07_advanced_sql.sql` to create a function, procedure, trigger, and perform a smoke test.

## Findings & Data Quality

- **Duplicate country codes** were found in `country_raw.csv` (see staging checks).
- Some **customers have missing country codes** or malformed birthdates.
- **Products** and **sales** with invalid or missing numeric fields are filtered out during transformation.
- **Quality checks** (`sql/06_quality_checks.sql`) ensure no nulls in keys, no orphaned foreign keys, and no negative sales.
- **Advanced SQL**: Includes a safe percentage function, a core refresh procedure (with transaction and error handling), a trigger to audit sales insertions, and a smoke test to validate pipeline health.

## Assumptions & Limitations

- The pipeline expects the CSVs to be imported as-is, with all cleaning done in SQL.
- Only MySQL syntax is supported (tested on MySQL 8+).
- Some data issues (e.g., missing country for some customers) are not fixed but flagged.
- The project is designed for clarity and reproducibility, not for large-scale performance.

---
