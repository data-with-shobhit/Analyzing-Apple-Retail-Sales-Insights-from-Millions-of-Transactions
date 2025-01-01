-- Business Problems and Solutions

-- 1.Find the number of stores in each country.

SELECT country , COUNT(store_id) as Total_Stores
FROM STORES
GROUP BY country
ORDER BY Total_Stores DESC;

-- 2.Calculate the total number of units sold by each store.

SELECT
    s.store_id,
    st.store_name,
    SUM(s.quantity) AS total_units_sold
FROM sales AS s
JOIN stores AS st
ON st.store_id = s.store_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 3.Identify how many sales occurred in January 2023.

SELECT COUNT(*) AS total_sales
FROM sales
WHERE TO_CHAR(sale_date, 'MM-YYYY') = '01-2023';

-- 4.Determine how many stores have never had a warranty claim filed.

SELECT COUNT(*) FROM stores
WHERE store_id NOT IN ( SELECT DISTINCT store_id
					    FROM sales AS s
						RIGHT JOIN warranty AS w
						ON s.sale_id=w.sale_id); 

-- 5.Calculate the percentage of warranty claims marked as "Rejected".

SELECT 
    ROUND(
        COUNT(claim_id) / (SELECT COUNT(*) FROM warranty)::numeric * 100, 2
    ) AS rejected_percentage
FROM warranty
WHERE repair_status = 'Rejected';


-- 6.Identify which store had the highest total units sold in the last year.

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

--7.Count the number of unique products sold in the last year.

SELECT 
    COUNT(DISTINCT product_id)
FROM sales
WHERE sale_date >= (SELECT CURRENT_DATE - INTERVAL '1 year');

--8.Find the average price of products in each category.

SELECT 
    p.category_id,
    c.category_name,
    ROUND(AVG(p.price)::NUMERIC, 2) AS avg_price
FROM products AS p
JOIN category AS c
ON p.category_id = c.category_id
GROUP BY 1, 2
ORDER BY 3 DESC;

-- 9.How many warranty claims were filed in 2024?

SELECT 
    COUNT(*) 
FROM warranty
WHERE EXTRACT(YEAR FROM claim_date) = 2024;

-- 10.For each store, identify the best-selling day based on highest quantity sold.

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

-- 11.Identify the least selling product in each country for each year based on total units sold.
	
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

-- 12.Calculate how many warranty claims were filed within 180 days of a product sale.

SELECT 
    COUNT(*) AS total_warranty_claimed
FROM warranty AS w
LEFT JOIN sales AS s
ON w.sale_id = s.sale_id
WHERE w.claim_date - s.sale_date <= 180;

-- 13.Determin how many warranty claims were filed for products launched in the last two years

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

-- 14. List the months in the last three years where sates exceeded units in the United States.

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

-- 15.Identify the product category with the most warranty claims filed in the last two years.

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

-- 16.Determine the percentage chance of receiving warranty claims after each purchase for each country.

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

-- 17.Analyze the year-by-year growth ratio for each store.

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


-- 18.Calculate the correlation between product price and warranty claims for products sold in the tast five years, segmented by price range.

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

-- 19.Identify the store with the highest percentage of "Completed" claims relative to total claims filed

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


-- 20.Write a query to calculate the monthly running total of sales for each store over the past four years and compare trends during this period.

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


						

