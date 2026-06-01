# Retail Sales Analysis SQL Project

## Project Overview

This is a SQL portfolio project where I analyzed a retail sales dataset using PostgreSQL.  
The goal of this project was to practice real data analyst tasks such as creating a table, cleaning data, exploring the dataset, and writing SQL queries to answer business questions.

The dataset contains retail transaction data, including customer information, product categories, sale dates, sale times, quantity, cost of goods sold, and total sales amount.

Through this project, I practiced SQL concepts such as filtering, grouping, aggregation, date functions, conditional logic, CTEs, and window functions.

---

## Tools Used

- PostgreSQL
- SQL
- PyCharm
- GitHub

---

## Dataset Structure

The project uses one main table called `retail_sales`.

```sql
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
```

The table contains the following columns:

| Column | Description |
|---|---|
| `transactions_id` | Unique transaction ID |
| `sale_date` | Date when the sale happened |
| `sale_time` | Time when the sale happened |
| `customer_id` | Unique customer ID |
| `gender` | Customer gender |
| `age` | Customer age |
| `category` | Product category |
| `quantity` | Number of items sold |
| `price_per_unit` | Price of one item |
| `cogs` | Cost of goods sold |
| `total_sale` | Total sale amount |

---

## Data Cleaning

Before starting the analysis, I checked the dataset for missing values.  
This is important because null values can affect the accuracy of the results.

```sql
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
```

After checking for null values, I removed records with missing important fields.

```sql
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
```

---

## Data Exploration

I started with basic exploration to understand the size of the dataset and the number of customers.

### Total number of sales records

```sql
SELECT COUNT(*) AS total_sale
FROM retail_sales;
```

### Total number of unique customers

```sql
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM retail_sales;
```

---

## Business Questions and SQL Analysis

In this section, I answered different business questions using SQL.

---

### 1. Sales made on a specific date

I retrieved all sales that happened on `2022-11-05`.

```sql
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';
```

This query can be useful when a business wants to review transactions from a specific day.

---

### 2. Clothing transactions in November 2022

I found all Clothing transactions where more than 3 items were sold in November 2022.

```sql
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
      AND quantity > 3
      AND sale_date >= '2022-11-01' 
      AND sale_date < '2022-12-01';
```

This helped me filter transactions by category, quantity, and date range.

---

### 3. Total sales by category

I calculated total sales and total number of orders for each product category.

```sql
SELECT category,
       SUM(total_sale) AS net_sale,
       COUNT(*) AS total_orders
FROM retail_sales
GROUP BY category;
```

This query shows which product categories generated the most revenue.

---

### 4. Average age of Beauty category customers

I calculated the average age of customers who bought products from the Beauty category.

```sql
SELECT ROUND(AVG(age), 2) AS average_age
FROM retail_sales
WHERE category = 'Beauty';
```

This can help understand the customer profile for a specific product category.

---

### 5. High-value transactions

I selected all transactions where the total sale amount was greater than 1000.

```sql
SELECT *
FROM retail_sales
WHERE total_sale > 1000;
```

This query helps identify high-value purchases.

---

### 6. Number of transactions by gender and category

I calculated how many transactions were made by each gender in each category.

```sql
SELECT category,
       gender,
       COUNT(*) AS total_trans
FROM retail_sales
GROUP BY category, gender
ORDER BY category;
```

This query can help compare customer purchasing behavior across gender and category.

---

### 7. Best-selling month in each year

I calculated the average sale for each month and used `RANK()` to find the best-performing month in each year.

```sql
SELECT year,
       month,
       avg_sale
FROM (
    SELECT 
        EXTRACT(YEAR FROM sale_date) AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        AVG(total_sale) AS avg_sale,
        RANK() OVER (
            PARTITION BY EXTRACT(YEAR FROM sale_date) 
            ORDER BY AVG(total_sale) DESC
        ) AS ranking
    FROM retail_sales
    GROUP BY 1, 2
) AS t
WHERE ranking = 1;
```

This query helped me practice window functions and monthly sales analysis.

---

### 8. Top 5 customers by total sales

I identified the top 5 customers based on their total spending.

```sql
SELECT customer_id,
       SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY customer_id
ORDER BY 2 DESC
LIMIT 5;
```

This query is useful for finding the most valuable customers.

---

### 9. Unique customers by category

I calculated how many unique customers purchased from each category.

```sql
SELECT category,
       COUNT(DISTINCT customer_id) AS cnt_unique_cs
FROM retail_sales
GROUP BY category;
```

This helped me understand customer reach for each product category.

---

### 10. Orders by shift

I grouped orders into three shifts: Morning, Afternoon, and Evening.  
I also calculated the percentage of total orders for each shift.

```sql
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
    ROUND((total_orders::NUMERIC / SUM(total_orders) OVER()) * 100, 2) 
        AS percentage_of_total_orders
FROM shift_counts
ORDER BY total_orders DESC;
```

This query helps analyze what time of day has the highest number of orders.

---

### 11. Repeat monthly purchasers

I counted customers who purchased in more than one month.

```sql
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
```

This query was used to identify repeat customers and measure customer loyalty.

---

### 12. Top-performing category by gender

I used `RANK()` to find the highest-revenue category for each gender.

```sql
WITH category_ranking AS (
    SELECT
        gender,
        category,
        SUM(total_sale) AS total_revenue,
        RANK() OVER (
            PARTITION BY gender 
            ORDER BY SUM(total_sale) DESC
        ) AS rank
    FROM retail_sales
    GROUP BY gender, category
)
SELECT
    gender,
    category,
    total_revenue
FROM category_ranking
WHERE rank = 1;
```

This helped me compare category performance across different customer groups.

---

### 13. Order size distribution

I analyzed order size by grouping transactions into single-item, medium, and large baskets.

```sql
SELECT
    category,
    COUNT(CASE WHEN quantity = 1 THEN 1 END) AS single_item_baskets,
    COUNT(CASE WHEN quantity BETWEEN 2 AND 3 THEN 1 END) AS medium_baskets,
    COUNT(CASE WHEN quantity >= 4 THEN 1 END) AS large_baskets,
    ROUND(AVG(quantity)::NUMERIC, 1) AS avg_items_per_order
FROM retail_sales
GROUP BY category;
```

This query shows whether customers usually buy one item or multiple items in each category.

---

### 14. Peak revenue anomalies

I calculated daily revenue and compared it with the overall daily average.  
Then I selected days where revenue was more than 3 times higher than the average.

```sql
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
    ROUND(((d.daily_total - b.overall_daily_avg) / b.overall_daily_avg * 100)::NUMERIC, 2) 
        AS percent_above_average
FROM daily_sales d
CROSS JOIN average_baseline b
WHERE d.daily_total > (b.overall_daily_avg * 3.0)
ORDER BY d.daily_total DESC
LIMIT 15;
```

This query can help detect unusually high sales days.

---

## SQL Skills Practiced

In this project, I practiced the following SQL skills:

- Creating tables
- Checking and deleting null values
- Filtering data with `WHERE`
- Aggregating data with `COUNT`, `SUM`, and `AVG`
- Grouping data with `GROUP BY`
- Sorting results with `ORDER BY`
- Working with dates using `EXTRACT` and `DATE_TRUNC`
- Using `CASE WHEN` for conditional logic
- Using CTEs with `WITH`
- Using window functions such as `RANK()`
- Using conditional aggregation
- Comparing daily sales with baseline averages

---

## Main Insights

Some of the main insights from the analysis include:

- Sales performance can be compared across different product categories.
- The Beauty category customer profile can be analyzed using average customer age.
- High-value transactions can be identified by filtering sales above 1000.
- Customer behavior can be compared by gender and category.
- Monthly sales trends can show the best-performing month in each year.
- Top customers can be identified based on total spending.
- Repeat monthly purchasers can be used as a simple customer loyalty indicator.
- Order time analysis can show whether most purchases happen in the morning, afternoon, or evening.
- Basket size analysis can show whether customers buy single or multiple items.
- Revenue anomaly analysis can help find unusually strong sales days.

---

## What I Learned

This project helped me improve my SQL skills by applying them to a realistic retail sales dataset.  
I practiced not only basic SQL queries, but also more analytical queries that can answer business questions.

The most useful parts for me were working with:

- CTEs
- Window functions
- Date-based analysis
- Conditional aggregation
- Customer and category-based analysis

This project also helped me understand how SQL can be used in real data analyst work to clean data, explore trends, and generate business insights.

---

## Author

**Alnur Turgaliyev**
