![image](https://github.com/user-attachments/assets/51b85aca-4b03-4063-8743-2e57d7051746)

# Analyzing Apple Retail Sales: Insights from Millions of Transactions

---
## Project Overview

The "Apple Retail Sales: Insights from Millions of Transactions" project is centered around analyzing a large dataset of retail sales transactions using SQL. The dataset encompasses millions of rows of sales data across multiple Apple retail stores, providing a rich source of information for uncovering business insights. The primary objective is to explore and extract meaningful patterns and trends that can inform business decisions.

---
## Entity Relationship Diagram (ERD)

![image](https://github.com/user-attachments/assets/755a0225-3370-4e5c-b3be-3c0f5236d7ee)

---

## Database Schema

### 1. **Stores**
Contains information about Apple retail stores.

| Column Name | Description                              |
|-------------|------------------------------------------|
| store_id    | Unique identifier for each store         |
| store_name  | Name of the store                        |
| city        | City where the store is located          |
| country     | Country of the store                    |

### 2. **Category**
Holds product category information.

| Column Name   | Description                              |
|---------------|------------------------------------------|
| category_id   | Unique identifier for each product category |
| category_name | Name of the category                    |


### 3. **Products**
Details about Apple products.

| Column Name   | Description                              |
|---------------|------------------------------------------|
| product_id    | Unique identifier for each product       |
| product_name  | Name of the product                      |
| category_id   | References the `category` table          |
| launch_date   | Date when the product was launched       |
| price         | Price of the product                    |

### 4. **Sales**
Stores sales transactions.

| Column Name   | Description                              |
|---------------|------------------------------------------|
| sale_id       | Unique identifier for each sale          |
| sale_date     | Date of the sale                         |
| store_id      | References the `stores` table            |
| product_id    | References the `products` table          |
| quantity      | Number of units sold                    |


### 5. **Warranty**
Contains information about warranty claims.

| Column Name   | Description                              |
|---------------|------------------------------------------|
| claim_id      | Unique identifier for each warranty claim |
| claim_date    | Date the claim was made                  |
| sale_id       | References the `sales` table             |
| repair_status | Status of the warranty claim (e.g., Paid Repaired, Warranty Void) |

---
 ## Objectives 
 This project aims to:

- Develop and demonstrate advanced SQL skills in joins, aggregations, window functions, and correlation analysis.
- Provide actionable insights by addressing business-related questions through SQL queries.

--- 

## Project Focus

This project highlights and demonstrates the following key SQL skills:

- Advanced Joins and Aggregations: Expertise in performing complex joins and aggregating data to extract meaningful insights.
- Window Functions: Proficiency in using window functions for tasks like running totals, growth analysis, and time-based evaluations.
- Data Segmentation: Skill in analyzing data across various time frames to assess product performance effectively.
- Correlation Analysis: Applying SQL functions to explore relationships between variables, such as the connection between product price and warranty claims.
- Practical Problem-Solving: Addressing business-relevant questions to simulate real-world challenges faced by data analysts.

---

## Solutions 

1. Find the number of stores in each country.
   
```sql
SELECT country , COUNT(store_id) as Total_Stores
FROM STORES
GROUP BY country
ORDER BY Total_Stores DESC;
```
2. Calculate the total number of units sold by each store.
   
```sql
SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```
3. Identify how many sales occurred in January 2023.

```sql
SELECT COUNT(*) AS total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '01-2023';
```
4. Determine how many stores have never had a warranty claim filed.
   
```sql
SELECT COUNT(*) FROM stores
WHERE store_id NOT IN ( SELECT DISTINCT store_id
					    FROM sales AS s
						RIGHT JOIN warranty AS w
						ON s.sale_id=w.sale_id);
```
5. Calculate the percentage of warranty claims marked as "Rejected".
```sql
SELECT 
    ROUND(
        COUNT(claim_id) / (SELECT COUNT(*) FROM warranty)::numeric * 100, 2
    ) AS rejected_percentage
FROM warranty
WHERE repair_status = 'Rejected';
```

6. Identify which store had the highest total units sold in the last year.
```sql
SELECT 
    s.store_id,
    st.store_name,
    SUM(s.quantity)
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
WHERE sale_date >= (SELECT CURRENT_DATE - INTERVAL '1 year')
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;
```

7. Count the number of unique products sold in the last year.
```sql
SELECT 
    COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (SELECT CURRENT_DATE - INTERVAL '1 year');
```

8. Find the average price of products in each category.
```sql
SELECT 
    p.category_id,
    c.category_name,
    ROUND(AVG(p.price)::NUMERIC, 2) AS avg_price
FROM products AS p
JOIN category AS c
ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;
```
9. How many warranty claims were filed in 2024?
```sql
SELECT 
    COUNT(*) 
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2024;
```
10. For each store, identify the best-selling day based on highest quantity sold.
```sql
SELECT * FROM
(
    SELECT
        store_id,
        TO_CHAR(sale_date, 'day') AS day_name,
        SUM(quantity) AS total_quantity_sold,
        RANK() OVER(PARTITION BY store_id ORDER BY SUM(quantity) DESC) AS rank
    FROM sales
    GROUP BY 1, 2
) AS tb1
WHERE rank = 1;
```
11. Identify the least selling product in each country for each year based on total units sold.
```sql	
WITH product_rank AS(
    SELECT 
        st.country,
        p.product_name,
        SUM(s.quantity) AS total_qty_sold,
        RANK() OVER(PARTITION BY st.country ORDER BY SUM(s.quantity)) AS least_sold_product
    FROM sales AS s
    JOIN stores AS st
    ON s.store_id = st.store_id
    JOIN products AS p
    ON s.product_id = p.product_id
    GROUP BY 1, 2
)
SELECT * FROM product_rank WHERE least_sold_product = 1;
```
12. Calculate how many warranty claims were filed within 180 days of a product sale.
```sql
SELECT 
    COUNT(*) AS total_warranty_claimed
FROM warranty AS w
LEFT JOIN sales AS s
ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date <= 180;
```
13. Determine how many warranty claims were filed for products launched in the last two years.
```sql
SELECT
    p.product_name,
    COUNT(w.claim_id) as total_no_claim,
    COUNT(s.sale_id) as total_no_sales
FROM warranty AS w
RIGHT JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE launch_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
HAVING COUNT(w.claim_id) > 0;
```
14. List the months in the last three years where sates exceeded units in the United States.
```sql
SELECT
    TO_CHAR(sale_date, 'MM-YYYY') AS months,
    SUM(s.quantity) AS no_of_units_sold
FROM sales AS s
JOIN stores AS st
ON s.store_id = st.store_id
WHERE country = 'United States' 
  AND s.sale_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY 1
HAVING SUM(s.quantity) > 5000;
```
15. Identify the product category with the most warranty claims filed in the last two years.
```sql
SELECT 
    c.category_name,
    COUNT(w.claim_id) AS total_claims
FROM warranty AS w
LEFT JOIN sales AS s
ON w.sale_id = s.sale_id
JOIN products AS p
ON p.product_id = s.product_id
JOIN category AS c
ON c.category_id = p.category_id
WHERE w.claim_date >= CURRENT_DATE - INTERVAL '2 years'
GROUP BY 1
ORDER BY 2 DESC;
```
16. Determine the percentage chance of receiving warranty claims after each purchase for each country.
```sql
SELECT
    country,
    total_units,
    total_claim,
    COALESCE((total_claim::NUMERIC / total_units::NUMERIC) * 100,0) AS percentage_of_risk
FROM
(
    SELECT
        st.country,
        SUM(s.quantity) AS total_units,
        COUNT(w.claim_id) AS total_claim
    FROM sales AS s
    JOIN stores AS st
    ON st.store_id = s.store_id
    LEFT JOIN warranty AS w
    ON w.sale_id = s.sale_id
    GROUP BY 1
) tr
ORDER BY 4 DESC;
```
17. Analyze the year-by-year growth ratio for each store.
```sql
WITH yearly_sales AS
(
    SELECT
        S.store_id,
        st.store_name,
        EXTRACT(YEAR FROM sale_date) AS year_of_sale,
        SUM(p.price * s.quantity) AS total_sale
    FROM sales AS s
    JOIN products AS p
    ON s.product_id = p.product_id
    JOIN stores AS st
    ON st.store_id = s.store_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 2, 3
),

growth_ratio AS
(
    SELECT
        store_name,
        year_of_sale,
        LAG(total_sale, 1) OVER(PARTITION BY store_name ORDER BY year_of_sale) AS last_year_sale,
        total_sale AS current_year_sale
    FROM yearly_sales
)

SELECT
    store_name,
    year_of_sale,
    last_year_sale,
    current_year_sale,
    ROUND((current_year_sale - last_year_sale)::NUMERIC / last_year_sale::NUMERIC * 100, 2) AS growth_ratio_yoy
FROM growth_ratio
WHERE last_year_sale IS NOT NULL;
```

18. Calculate the correlation between product price and warranty claims for products sold in the tast five years, segmented by price range.
```sql
SELECT 
    CASE
        WHEN p.price < 500 THEN 'Basic'
        WHEN p.price BETWEEN 500 AND 1000 THEN 'Mid-range'
        ELSE 'Premium'
    END AS price_segment,
    COUNT(w.claim_id) AS total_claim
FROM warranty AS w
LEFT JOIN sales AS s
ON s.sale_id = w.sale_id
JOIN products AS p
ON p.product_id = s.product_id
WHERE claim_date >= CURRENT_DATE - INTERVAL '5 years'
GROUP BY 1
ORDER BY 2 DESC;
```
19. Identify the store with the highest percentage of "Completed" claims relative to total claims filed.
    
```sql
WITH completed AS
(
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS completed
    FROM sales AS s
    RIGHT JOIN warranty AS w
    ON s.sale_id = w.sale_id
    WHERE w.repair_status = 'Completed'
    GROUP BY 1
), 

total_claim AS
(
    SELECT
        s.store_id,
        COUNT(w.claim_id) AS total_claim
    FROM sales AS s
    RIGHT JOIN warranty AS w
    ON s.sale_id = w.sale_id
    GROUP BY 1
)

SELECT 
    tc.store_id,
	st.store_name,
    tc.total_claim,
    c.completed,
    ROUND(c.completed::NUMERIC / tc.total_claim::NUMERIC * 100, 2) AS percentage_of_completed
FROM completed AS c
JOIN total_claim AS tc
ON c.store_id = tc.store_id
JOIN stores AS st
ON tc.store_id=st.store_id;
```

20. Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.
```sql
WITH monthly_sales AS
(
    SELECT
        store_id,
        EXTRACT(YEAR FROM sale_date) AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        SUM(p.price * s.quantity) AS total_profit
    FROM sales AS s
    JOIN products AS p
    ON s.product_id = p.product_id
    GROUP BY 1, 2, 3
    ORDER BY 1, 2, 3
)

SELECT
    store_id, 
    year, 
    month, 
    total_profit, 
    SUM(total_profit) OVER(PARTITION BY store_id ORDER BY year, month) AS running_total
FROM monthly_sales;
```
---

## Dataset  

- **Size:** Contains more than 1 million rows of detailed sales records.  
- **Time Period:** Covers 4 years, providing data for long-term trend analysis.  
- **Geographical Scope:** Includes sales information from 70+ Apple stores in 15+ countries .

---  

## Conclusion  

- This project successfully demonstrates the application of advanced SQL techniques to analyze and derive insights from a large dataset of Apple retail sales. By utilizing complex joins, aggregations, window functions, and correlation analysis, the project provides actionable insights into product performance, sales trends, and warranty claims across multiple years and geographical regions.  

- The skills and methodologies showcased in this project emphasize the importance of SQL in solving real-world business problems, highlighting its role in efficient data exploration and decision-making. This analysis can be further extended to include more dimensions, such as customer segmentation or predictive analytics, to deepen business insights and drive strategic growth.

---  








