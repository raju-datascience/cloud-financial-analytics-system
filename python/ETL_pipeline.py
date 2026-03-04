# ==============================
# FINANCIAL ANALYTICS ETL SCRIPT
# ==============================

import pandas as pd
from sqlalchemy import create_engine, text

print("Starting ETL Pipeline...")

# --------------------------------
# 1. DATABASE CONNECTION
# --------------------------------

DB_USER = "admin"
DB_PASSWORD = "raju1234"
DB_HOST = "financial-analytics-db.cve6u2aeszkj.eu-north-1.rds.amazonaws.com"
DB_PORT = "3306"
DB_NAME = "financial_analytics_2025"

engine = create_engine(
    f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

print("Connected to AWS RDS")

# --------------------------------
# 2. EXTRACT (READ CSV FILES)
# --------------------------------

income_df = pd.read_csv("income_2025.csv")
expense_df = pd.read_csv("expense_2025.csv")

print("CSV files loaded")

# --------------------------------
# 3. TRANSFORM (LIGHT CLEANING)
# --------------------------------

income_df.columns = income_df.columns.str.strip()
expense_df.columns = expense_df.columns.str.strip()

income_df["month_name"] = income_df["month_name"].str.title()
expense_df["month_name"] = expense_df["month_name"].str.title()

print("Data cleaned")

# --------------------------------
# 4. LOAD → STAGING TABLES
# --------------------------------

print("Loading staging_income...")

income_df.to_sql(
    "staging_income",
    engine,
    if_exists="replace",   # safe refresh
    index=False
)

print("Loading staging_expense...")

expense_df.to_sql(
    "staging_expense",
    engine,
    if_exists="replace",
    index=False
)

print("Staging tables updated")

# --------------------------------
# 5. RUN SQL TRANSFORMATIONS
# (Same logic you already created)
# --------------------------------

with engine.connect() as conn:

    print("Updating fact_income...")

    conn.execute(text("""
        DELETE FROM fact_income;
    """))

    conn.execute(text("""
        INSERT INTO fact_income (date_id, income_source_id, amount)
        SELECT d.date_id, 1, s.salary
        FROM staging_income s
        JOIN dim_date d ON s.month_name = d.month_name;
    """))

    conn.execute(text("""
        INSERT INTO fact_income (date_id, income_source_id, amount)
        SELECT d.date_id, 2, s.overtime_amount
        FROM staging_income s
        JOIN dim_date d ON s.month_name = d.month_name;
    """))

    conn.execute(text("""
        INSERT INTO fact_income (date_id, income_source_id, amount)
        SELECT d.date_id, 3, s.finance_interest
        FROM staging_income s
        JOIN dim_date d ON s.month_name = d.month_name;
    """))

    conn.execute(text("""
        INSERT INTO fact_income (date_id, income_source_id, amount)
        SELECT d.date_id, 4, s.rent_amount
        FROM staging_income s
        JOIN dim_date d ON s.month_name = d.month_name;
    """))

    print("Updating fact_expense...")

    conn.execute(text("""
        DELETE FROM fact_expense;
    """))

    conn.execute(text("""
        INSERT INTO fact_expense (date_id, category_id, amount)
        SELECT d.date_id, c.category_id, s.amount
        FROM staging_expense s
        JOIN dim_date d ON s.month_name = d.month_name
        JOIN dim_category c ON s.category_name = c.category_name;
    """))

print("Warehouse updated successfully")

print("ETL Pipeline Completed Successfully")