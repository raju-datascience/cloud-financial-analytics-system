CREATE DATABASE financial_analytics_2025;

USE financial_analytics_2025;

CREATE TABLE dim_date (
    date_id INT AUTO_INCREMENT PRIMARY KEY,
    month_number INT NOT NULL,
    month_name VARCHAR(20) NOT NULL,
    year INT NOT NULL
);

CREATE TABLE dim_income_source (
    income_source_id INT AUTO_INCREMENT PRIMARY KEY,
    income_source_name VARCHAR(50) NOT NULL,
    income_type VARCHAR(20) NOT NULL
);

CREATE TABLE dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL
);

CREATE TABLE fact_income (
    income_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id INT NOT NULL,
    income_source_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (income_source_id) REFERENCES dim_income_source(income_source_id)
);

CREATE TABLE staging_income (
    month_name VARCHAR(20),
    salary DECIMAL(12,2),
    overtime_amount DECIMAL(12,2),
    finance_interest DECIMAL(12,2),
    rent_amount DECIMAL(12,2)
);

SELECT * FROM staging_income;

INSERT INTO fact_income (date_id, income_source_id, amount)
SELECT 
    d.date_id,
    1 AS income_source_id,
    s.salary
FROM staging_income s
JOIN dim_date d 
    ON s.month_name = d.month_name;
    
INSERT INTO fact_income (date_id, income_source_id, amount)
SELECT 
    d.date_id,
    2 AS income_source_id,
    s.overtime_amount
FROM staging_income s
JOIN dim_date d 
    ON s.month_name = d.month_name;
    
INSERT INTO fact_income (date_id, income_source_id, amount)
SELECT 
    d.date_id,
    3 AS income_source_id,
    s.finance_interest
FROM staging_income s
JOIN dim_date d 
    ON s.month_name = d.month_name;
    
INSERT INTO fact_income (date_id, income_source_id, amount)
SELECT 
    d.date_id,
    4 AS income_source_id,
    s.rent_amount
FROM staging_income s
JOIN dim_date d 
    ON s.month_name = d.month_name;
    
SELECT COUNT(*) FROM fact_income;

SELECT * FROM fact_income ORDER BY date_id, income_source_id;

CREATE TABLE fact_expense (
    expense_id INT AUTO_INCREMENT PRIMARY KEY,
    date_id INT NOT NULL,
    category_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,

    FOREIGN KEY (date_id) REFERENCES dim_date(date_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id)
);

CREATE TABLE staging_expense (
    month_name VARCHAR(20),
    category_name VARCHAR(100),
    amount DECIMAL(12,2)
);

SELECT COUNT(*) FROM staging_expense;

SELECT * FROM staging_expense LIMIT 10;

INSERT INTO fact_expense (date_id, category_id, amount)
SELECT 
    d.date_id,
    c.category_id,
    s.amount
FROM staging_expense s
JOIN dim_date d
    ON s.month_name = d.month_name
JOIN dim_category c
    ON s.category_name = c.category_name;
    
SELECT COUNT(*) FROM fact_expense;

SELECT * 
FROM fact_expense
ORDER BY date_id, category_id
LIMIT 20;
