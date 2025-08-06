
--Exploratory Data Analysis (EDA)	
USE PortfolioProject2;

-------------------------------------------------------------------------------
SELECT TOP 5 * FROM categories;
SELECT TOP 5 * FROM cities;
SELECT TOP 5 * FROM countries;
SELECT TOP 5 * FROM customers;
SELECT TOP 5 * FROM employees;
SELECT TOP 5 * FROM products;
SELECT TOP 5 * FROM sales
-------------------------------------------------------------------------------
--1. Monthly Sales Overview

--General monthly sales
SELECT 
	FORMAT(sales_date,'yyyy-MM') AS sales_month,
	SUM(total_price) AS monthly_revenue,
	COUNT(*) AS transactions
FROM sales
GROUP BY FORMAT(sales_date,'yyyy-MM')
ORDER BY sales_month;

--Category-wise monthly sales

SELECT
	FORMAT(s.sales_date,'yyyy-MM') AS sales_month,
	c.category_name,
	SUM(s.total_price) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
JOIN categories c ON p.category_id = c.category_id
GROUP BY FORMAT(s.sales_date,'yyyy-MM'),c.category_name
ORDER BY total_revenue DESC;
-------------------------------------------------------------------------------
--2. Top and bottom products by Revenue

-- Top 10
SELECT TOP 10
	p.product_name,
	SUM(s.total_price) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- Bottom 10
SELECT TOP 10
	p.product_name,
	SUM(s.total_price) AS total_revenue
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue;
-------------------------------------------------------------------------------
--3. Customer Segmentation (RFM-like)

--Step1: Create Basic RFM metrics
WITH RFM_Base AS(
	SELECT
		customer_id,
		MAX(CAST(sales_date AS DATE)) AS last_purchase,
		COUNT(DISTINCT transaction_number) AS frequency,
		SUM(total_price) AS monetary
	FROM sales
	GROUP BY customer_id
),
--Step2: Caculate Recnecy using latest date in dataset
RFM_Recency AS (
    SELECT *,
         -- Recency = days since last purchase (latest date is dynamic)
        DATEDIFF(DAY, last_purchase, (SELECT MAX(CAST(sales_date AS DATE)) FROM sales)) AS recency
    FROM RFM_Base
),
--Step3: Score Recency (low is better), Frequency and Monetary (high is better)
RFM_Scored AS (
    SELECT *,
        -- Recency Score: 5 = most recent
        6 - NTILE(5) OVER (ORDER BY recency) AS recency_score,

        -- Frequency Score: 5 = most frequent
        NTILE(5) OVER (ORDER BY frequency) AS frequency_score,

        -- Monetary Score: 5 = highest spender
        NTILE(5) OVER (ORDER BY monetary) AS monetary_score
    FROM RFM_Recency
),
--Step4: Final Output with RFM segment and label
Final_RFM AS (
    SELECT
        customer_id,
        recency,
        frequency,
        monetary,
        recency_score,
        frequency_score,
        monetary_score,
        
        -- RFM code: e.g., 543
        CAST(recency_score AS VARCHAR) +
        CAST(frequency_score AS VARCHAR) +
        CAST(monetary_score AS VARCHAR) AS rfm_segment,

        -- Simple segment label
        CASE 
            WHEN recency_score = 5 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Best Customer'
            WHEN recency_score <= 2 AND frequency_score >= 4 THEN 'At Risk'
            WHEN frequency_score >= 4 THEN 'Loyal'
            WHEN recency_score = 5 THEN 'New Customer'
            WHEN frequency_score = 1 AND monetary_score = 1 THEN 'Lost/one-time'
            ELSE 'Others'
        END AS segment_label
    FROM RFM_Scored
)
-- STEP 5: Show final result
SELECT *
FROM Final_RFM
ORDER BY rfm_segment DESC;
-------------------------------------------------------------------------------
--4. Salesperson Performace

SELECT 
    e.employee_id,
    CONCAT(e.first_name,' ',e.last_name) AS employee_name,
    COUNT(s.sales_id) AS transaction_count,
    SUM(s.total_price) AS total_revenue
FROM sales s 
JOIN employees e ON s.salesperson_id = e.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY total_revenue DESC;
-------------------------------------------------------------------------------
--5. Ranking Products

SELECT 
    p.product_id,
    p.product_name,
    SUM(s.total_price) AS revenue,
    RANK() OVER (ORDER BY SUM(s.total_price) DESC) AS revenue_ranking
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY p.product_id,p.product_name
-------------------------------------------------------------------------------
--6. Geographical Insights

SELECT
    co.country_name,
    ci.city_name,
    SUM(s.total_price) AS total_revenue
FROM sales s
JOIN customers cu ON s.customer_id = cu.customer_id
JOIN cities ci ON cu.city_id = ci.city_id
JOIN countries co ON ci.country_id = co.country_id
GROUP BY co.country_name, ci.city_name
ORDER BY total_revenue DESC;



