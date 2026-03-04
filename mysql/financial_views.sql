SELECT 
    d.month_name,
    SUM(f.amount) AS total_income
FROM fact_income f
JOIN dim_date d 
    ON f.date_id = d.date_id
GROUP BY d.month_name, d.month_number
ORDER BY d.month_number;


SELECT 
    d.month_name,
    d.month_number,
    SUM(fe.amount) AS total_expense
FROM fact_expense fe
JOIN dim_date d 
    ON fe.date_id = d.date_id
GROUP BY d.month_name, d.month_number
ORDER BY d.month_number;


CREATE OR REPLACE VIEW vw_monthly_summary AS
SELECT 
    d.month_name,
    d.month_number,
    
    COALESCE(i.total_income, 0) AS total_income,
    COALESCE(e.total_expense, 0) AS total_expense,
    
    COALESCE(i.total_income, 0) - COALESCE(e.total_expense, 0) AS savings,
    
    ROUND(
        (COALESCE(i.total_income, 0) - COALESCE(e.total_expense, 0))
        / NULLIF(COALESCE(i.total_income, 0), 0) * 100
    , 2) AS savings_percentage

FROM dim_date d

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_income
    FROM fact_income
    GROUP BY date_id
) i ON d.date_id = i.date_id

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_expense
    FROM fact_expense
    GROUP BY date_id
) e ON d.date_id = e.date_id

ORDER BY d.month_number;

SELECT * FROM vw_monthly_summary;

CREATE OR REPLACE VIEW vw_income_split AS
SELECT 
    d.month_name,
    d.month_number,
    
    SUM(
        CASE 
            WHEN dis.income_type = 'Active' 
            THEN fi.amount 
            ELSE 0 
        END
    ) AS active_income,
    
    SUM(
        CASE 
            WHEN dis.income_type = 'Passive' 
            THEN fi.amount 
            ELSE 0 
        END
    ) AS passive_income

FROM fact_income fi

JOIN dim_income_source dis
    ON fi.income_source_id = dis.income_source_id

JOIN dim_date d
    ON fi.date_id = d.date_id

GROUP BY d.month_name, d.month_number
ORDER BY d.month_number;

SELECT * FROM vw_income_split;



CREATE OR REPLACE VIEW vw_category_analysis AS
SELECT 
    c.category_name,
    
    SUM(fe.amount) AS total_expense,
    
    ROUND(
        SUM(fe.amount) / 
        (SELECT SUM(amount) FROM fact_expense) * 100
    , 2) AS percentage_contribution

FROM fact_expense fe

JOIN dim_category c
    ON fe.category_id = c.category_id

GROUP BY c.category_name

ORDER BY total_expense DESC;

SELECT * FROM vw_category_analysis;



CREATE OR REPLACE VIEW vw_growth_analysis AS
SELECT 
    month_name,
    month_number,
    total_income,
    total_expense,
    
    ROUND(
        (total_income - LAG(total_income) OVER (ORDER BY month_number)) 
        / NULLIF(LAG(total_income) OVER (ORDER BY month_number), 0) * 100
    , 2) AS income_growth_percentage,
    
    ROUND(
        (total_expense - LAG(total_expense) OVER (ORDER BY month_number)) 
        / NULLIF(LAG(total_expense) OVER (ORDER BY month_number), 0) * 100
    , 2) AS expense_growth_percentage

FROM vw_monthly_summary;

SELECT * FROM vw_growth_analysis;




CREATE OR REPLACE VIEW vw_cumulative_savings AS
SELECT 
    month_name,
    month_number,
    savings,
    
    SUM(savings) OVER (
        ORDER BY month_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_savings

FROM vw_monthly_summary;

SELECT * FROM vw_cumulative_savings;

CREATE OR REPLACE VIEW monthly_summary AS
SELECT 
    d.date_id,
    d.month_number,
    d.month_name,
    d.year,
    
    SUM(fi.amount) AS total_income,
    SUM(fe.amount) AS total_expense,
    SUM(fi.amount) - SUM(fe.amount) AS savings,
    
    ROUND(
        (SUM(fi.amount) - SUM(fe.amount)) / SUM(fi.amount) * 100,
        2
    ) AS savings_percentage

FROM dim_date d
LEFT JOIN fact_income fi ON d.date_id = fi.date_id
LEFT JOIN fact_expense fe ON d.date_id = fe.date_id
GROUP BY d.date_id, d.month_number, d.month_name, d.year
ORDER BY d.month_number;





CREATE OR REPLACE VIEW income_split AS
SELECT
    d.month_number,
    d.month_name,
    dis.income_type,
    SUM(fi.amount) AS total_income
FROM fact_income fi
JOIN dim_date d ON fi.date_id = d.date_id
JOIN dim_income_source dis 
    ON fi.income_source_id = dis.income_source_id
GROUP BY d.month_number, d.month_name, dis.income_type
ORDER BY d.month_number;




CREATE OR REPLACE VIEW category_analysis AS
SELECT
    dc.category_id,
    dc.category_name,
    SUM(fe.amount) AS total_expense
FROM fact_expense fe
JOIN dim_category dc 
    ON fe.category_id = dc.category_id
GROUP BY dc.category_id, dc.category_name
ORDER BY total_expense DESC;





CREATE OR REPLACE VIEW category_monthly_trend AS
SELECT
    d.month_number,
    d.month_name,
    dc.category_name,
    SUM(fe.amount) AS total_expense
FROM fact_expense fe
JOIN dim_date d ON fe.date_id = d.date_id
JOIN dim_category dc 
    ON fe.category_id = dc.category_id
GROUP BY 
    d.month_number,
    d.month_name,
    dc.category_name
ORDER BY d.month_number;




CREATE OR REPLACE VIEW savings_waterfall AS
SELECT
    d.month_number,
    d.month_name,
    SUM(fi.amount) - SUM(fe.amount) AS monthly_savings
FROM dim_date d
LEFT JOIN fact_income fi ON d.date_id = fi.date_id
LEFT JOIN fact_expense fe ON d.date_id = fe.date_id
GROUP BY d.month_number, d.month_name
ORDER BY d.month_number;

CREATE OR REPLACE VIEW vw_monthly_summary AS

SELECT
    d.month_number,
    d.month_name,
    d.year,
    COALESCE(i.total_income,0) AS total_income,
    COALESCE(e.total_expense,0) AS total_expense,
    COALESCE(i.total_income,0) - COALESCE(e.total_expense,0) AS savings,
    ROUND(
        (COALESCE(i.total_income,0) - COALESCE(e.total_expense,0)) 
        / COALESCE(i.total_income,1) * 100, 2
    ) AS savings_percentage

FROM dim_date d

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_income
    FROM fact_income
    GROUP BY date_id
) i ON d.date_id = i.date_id

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_expense
    FROM fact_expense
    GROUP BY date_id
) e ON d.date_id = e.date_id

ORDER BY d.month_number;

select * from vw_monthly_summary;


CREATE OR REPLACE VIEW vw_income_split AS
SELECT
    d.month_number,
    d.month_name,
    s.income_type,
    SUM(fi.amount) AS total_income
FROM fact_income fi
JOIN dim_date d ON fi.date_id = d.date_id
JOIN dim_income_source s ON fi.income_source_id = s.income_source_id
GROUP BY d.month_number, d.month_name, s.income_type
ORDER BY d.month_number;

select * from vw_income_split;

CREATE OR REPLACE VIEW vw_category_analysis AS
SELECT
    c.category_id,
    c.category_name,
    SUM(fe.amount) AS total_expense
FROM fact_expense fe
JOIN dim_category c ON fe.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_expense DESC;

select * from vw_category_analysis;



CREATE OR REPLACE VIEW vw_category_monthly_trend AS
SELECT
    d.month_number,
    d.month_name,
    c.category_name,
    SUM(fe.amount) AS total_expense
FROM fact_expense fe
JOIN dim_date d ON fe.date_id = d.date_id
JOIN dim_category c ON fe.category_id = c.category_id
GROUP BY d.month_number, d.month_name, c.category_name
ORDER BY d.month_number;

select * from vw_category_monthly_trend;


CREATE OR REPLACE VIEW vw_savings_waterfall AS

SELECT
    d.month_number,
    d.month_name,
    COALESCE(i.total_income,0) - COALESCE(e.total_expense,0) AS monthly_savings

FROM dim_date d

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_income
    FROM fact_income
    GROUP BY date_id
) i ON d.date_id = i.date_id

LEFT JOIN (
    SELECT date_id, SUM(amount) AS total_expense
    FROM fact_expense
    GROUP BY date_id
) e ON d.date_id = e.date_id

ORDER BY d.month_number;

select * from vw_savings_waterfall;
