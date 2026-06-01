-- SQL Retail Sales Analysis

-- Create TABLE
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
            (
                transactions_id INT PRIMARY KEY,
                sale_date DATE,
                sale_time TIME,
                customer_id INT,
                gender VARCHAR(15),
                age INT,
                category VARCHAR(15),
                quantity INT,
                price_per_unit FLOAT,
                cogs FLOAT,
                total_sale FLOAT
            );

-- Data Cleaning

SELECT *
FROM retail_sales
WHERE
    transactions_id IS NULL
    OR sale_date IS NULL
    OR sale_time IS NULL
    OR gender IS NULL
    OR category IS NULL
    OR quantity IS NULL
    OR cogs IS NULL
    OR total_sale IS NULL;


DELETE FROM retail_sales
WHERE
    transactions_id IS NULL
    OR sale_date IS NULL
    OR sale_time IS NULL
    OR gender IS NULL
    OR category IS NULL
    OR quantity IS NULL
    OR cogs IS NULL
    OR total_sale IS NULL;

-- Data Exploration

-- How many sales we have?
SELECT COUNT(*) AS total_sale
FROM retail_sales;

-- How many unique customers we have?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retail_sales;

-- Data Analysis & Business Key Problems & Answer

-- My Analysis & Findings
-- Q.1 Write a SQL query to retrieve all columns for sales made on '2022-11-05
-- Q.2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 10 in the month of Nov-2022
-- Q.3 Write a SQL query to calculate the total sales (total_sale) for each category.
-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category.
-- Q.5 Write a SQL query to find all transactions where the total_sale is greater than 1000.
-- Q.6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category.
-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
-- Q.8 Write a SQL query to find the top 5 customers based on the highest total sales
-- Q.9 Write a SQL query to find the number of unique customers who purchased items from each category.
-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <=12, Afternoon Between 12 & 17, Evening >17)
-- Q.11 Identify customer loyalty by counting repeat monthly purchasers
-- Q.12 Find the top-performing sales category for each gender using RANK()
-- Q.13 Analyze order size distribution using conditional aggregations
-- Q.14 Identify Top Peak Revenue Anomalies (3x+ Baseline Average)

-- Q.1 Write a SQL query to retrieve all columns for sales made on '2022-11-05'
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';


-- Q.2 Write a SQL query to retrieve all transactions where the category is 'Clothing' and the quantity sold is more than 3 in the month of Nov-2022
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
      AND quantity > 3
      AND sale_date >= '2022-11-01' AND sale_date < '2022-12-01';


-- Q.3 Write a SQL query to calculate the total sales (total_sale) for each category
SELECT category,
       SUM(total_sale) AS net_sale,
       COUNT(*) AS total_orders
FROM retail_sales
GROUP BY category;


-- Q.4 Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category
SELECT ROUND(AVG(age), 2) AS average_age
FROM retail_sales
WHERE category = 'Beauty';


-- Q.5 Write a SQL query to find all transactions where the total_sale is greater than 1000
SELECT *
FROM retail_sales
WHERE total_sale > 1000;


-- Q.6 Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category
SELECT category,
       gender,
       COUNT(*) AS total_trans
FROM retail_sales
GROUP BY category, gender
ORDER BY category;


-- Q.7 Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
SELECT year,
       month,
       avg_sale
FROM (
SELECT EXTRACT(YEAR FROM sale_date) AS year,
       EXTRACT(MONTH FROM sale_date) AS month,
       AVG(total_sale) AS avg_sale,
       RANK() OVER (PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) AS ranking
FROM retail_sales
GROUP BY 1, 2) AS t
WHERE ranking = 1;


-- Q.8 Write a SQL query to find the top 5 customers based on the highest total sales
SELECT customer_id,
       SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY 2 DESC
LIMIT 5;


-- Q.9 Write a SQL query to find the number of unique customers who purchased items from each category
SELECT category,
       COUNT(DISTINCT customer_id) AS cnt_unique_cs
FROM retail_sales
GROUP BY category;


-- Q.10 Write a SQL query to create each shift and number of orders (Example Morning <=12, Afternoon Between 12 & 17, Evening >17)
WITH shift_counts AS (
    SELECT
        CASE
            WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
            ELSE 'Evening'
        END AS shift,
        COUNT(*) AS total_orders
    FROM retail_sales
    GROUP BY 1
)

SELECT
    shift,
    total_orders,
    ROUND((total_orders::NUMERIC / SUM(total_orders) OVER()) * 100, 2) AS percentage_of_total_orders
FROM shift_counts
ORDER BY total_orders DESC;


-- Q.11 Identify customer loyalty by counting repeat monthly purchasers
WITH monthly_customer_counts AS (
    SELECT
        customer_id,
        COUNT(DISTINCT DATE_TRUNC('month', sale_date)) AS active_months
    FROM retail_sales
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS total_repeat_customers
FROM monthly_customer_counts
WHERE active_months > 1;


-- Q.12 Find the top-performing sales category for each gender using RANK()
WITH category_ranking AS (
    SELECT
        gender,
        category,
        SUM(total_sale) AS total_revenue,
        RANK() OVER (PARTITION BY gender ORDER BY SUM(total_sale) DESC) AS rank
    FROM retail_sales
    GROUP BY gender, category
)
SELECT
    gender,
    category,
    total_revenue
FROM category_ranking
WHERE rank = 1;


-- Q.13 Analyze order size distribution using conditional aggregations
SELECT
    category,
    COUNT(CASE WHEN quantity = 1 THEN 1 END) AS single_item_baskets,
    COUNT(CASE WHEN quantity BETWEEN 2 AND 3 THEN 1 END) AS medium_baskets,
    COUNT(CASE WHEN quantity >= 4 THEN 1 END) AS large_baskets,
    ROUND(AVG(quantity)::NUMERIC, 1) AS avg_items_per_order
FROM retail_sales
GROUP BY category;


-- Q.14 Identify Top Peak Revenue Anomalies (3x+ Baseline Average)
WITH daily_sales AS (
    SELECT
        sale_date,
        SUM(total_sale) AS daily_total
    FROM retail_sales
    GROUP BY sale_date
),
average_baseline AS (
    SELECT AVG(daily_total) AS overall_daily_avg
    FROM daily_sales
)
SELECT
    d.sale_date,
    d.daily_total,
    ROUND(b.overall_daily_avg::NUMERIC, 2) AS baseline_avg,
    ROUND(((d.daily_total - b.overall_daily_avg) / b.overall_daily_avg * 100)::NUMERIC, 2) AS percent_above_average
FROM daily_sales d
CROSS JOIN average_baseline b
WHERE d.daily_total > (b.overall_daily_avg * 3.0)
ORDER BY d.daily_total DESC
LIMIT 15;


--End of Project