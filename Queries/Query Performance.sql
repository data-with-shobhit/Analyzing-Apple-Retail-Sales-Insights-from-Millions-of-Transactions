select * from category;
select * from products;
select * from sales;
select * from stores;
select * from warranty;

---EDA---
SELECT DISTINCT repair_status FROM warranty;

SELECT DISTINCT store_name FROM stores;

SELECT COUNT(*) FROM sales;

SELECT DISTINCT category_name FROM category;

SELECT DISTINCT product_name FROM products;

----- Improving Query Performance---------

 -- Planning Time :0.091ms
 -- Excecution Time : 152.279 ms 
 
EXPLAIN ANALYZE
SELECT * FROM sales
WHERE store_id='ST-31';

CREATE INDEX sales_product_id ON sales(product_id);

CREATE INDEX sales_store_id ON sales(store_id); 

CREATE INDEX sale_date ON sales(sale_date);

---- After index
 -- Planning Time :1.796 ms
 -- Excecution Time : 7.785 ms





 
