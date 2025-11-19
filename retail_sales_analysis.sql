-- Retail Sales Analysis

-- creating table
DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales(
transactions_id INT PRIMARY KEY,
sale_date DATE,
sale_time TIME,
customer_id INT,
gender VARCHAR(15),
age INT,
category VARCHAR(15),
quantiy INT,
price_per_unit FLOAT,
cogs FLOAT,
total_sale FLOAT
);

--Determine the total number of records in the dataset
SELECT COUNT(*) FROM retail_sales;

--Find out how many unique customers are in the dataset
SELECT COUNT(DISTINCT customer_id)
FROM retail_sales;

-- Identify all unique product categories in the dataset
SELECT DISTINCT category
FROM retail_sales;

-- Check for any null values in the dataset and delete records with missing data
SELECT * FROM
retail_sales
WHERE 
sale_date IS NULL OR sale_time IS NULL OR 
customer_id IS NULL OR age IS NULL OR category IS NULL OR
quantiy IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

DELETE FROM retail_sales 
WHERE sale_date IS NULL OR sale_time IS NULL OR 
customer_id IS NULL OR age IS NULL OR category IS NULL OR
quantiy IS NULL OR price_per_unit IS NULL OR cogs IS NULL;

-- Write a SQL query to retrieve all columns for sales made on '2022-11-05'
SELECT * 
FROM retail_sales
WHERE sale_date ='2022-11-05';

-- Write a SQL query to retrieve all transactions where the category is 
-- 'Clothing' and the quantity sold is more than 4 in the month of Nov-2022
SELECT * 
FROM retail_sales
WHERE category = 'Clothing' AND quantiy >=4 AND TO_CHAR(sale_date, 'YYYY-MM') = '2022-11';

-- Write a SQL query to calculate the total sales (total_sale) for each category
SELECT category, 
		SUM(total_sale) AS net_sale,
		COUNT(*) AS total_order
FROM retail_sales
GROUP BY category;

-- Write a SQL query to find the total number of transactions (transaction_id) made by each gender in each category
SELECT category, gender, COUNT(*) AS total_trans
FROM retail_sales
GROUP BY category, gender
ORDER BY 1;

--Write a SQL query to calculate the average sale for each month. Find out best selling month in each year
SELECT TO_CHAR(sale_date, 'MM') AS months, AVG(total_sale)
FROM retail_sales
GROUP BY TO_CHAR(sale_date, 'MM')
ORDER BY 2 DESC;
--(alternative)
SELECT year, month, avg_sale 
FROM 
(SELECT 
	EXTRACT(YEAR FROM sale_date) AS year,
	EXTRACT(MONTH FROM sale_date) AS month,
	AVG(total_sale) AS avg_sale,
	RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) AS rank
FROM retail_sales
GROUP BY 1, 2
) AS T1
WHERE rank = 1;

--Write a SQL query to find the top 5 customers based on the highest total sales
SELECT customer_id
FROM retail_sales
GROUP BY customer_id
ORDER BY SUM(total_sale) DESC
LIMIT 5;

-- Write a SQL query to find the number of unique customers who purchased items from each category
SELECT category,
	COUNT(DISTINCT customer_id) AS nb_distinct_cust
FROM retail_sales
GROUP BY 1;

--Write a SQL query to create each shift and number of orders (Example Morning <12, Afternoon Between 12 & 17, Evening >17)
WITH hourly_sale AS 
(SELECT *,
	CASE 
	WHEN EXTRACT(HOUR FROM sale_time)<12 THEN 'Morning'
	WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
	WHEN EXTRACT(HOUR FROM sale_time)>17 THEN 'Evening'
	END AS shift
FROM retail_sales)
SELECT shift, COUNT(*)
FROM hourly_sale
GROUP BY shift;