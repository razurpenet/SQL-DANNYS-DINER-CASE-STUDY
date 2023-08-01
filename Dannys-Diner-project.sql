/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
-- 2. How many days has each customer visited the restaurant?
-- 3. What was the first item from the menu purchased by each customer?
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:
SELECT
  	product_id,
    product_name,
    price
FROM dannys_diner.menu
ORDER BY price DESC
LIMIT 5;

SELECT *
FROM dannys_diner.members

SELECT *
FROM dannys_diner.menu

SELECT *
FROM dannys_diner.sales

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS total_spent
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_spent DESC

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS number_of_days
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY customer_id 

-- 3. What was the first item from the menu purchased by each customer?
with ranking as(SELECT s.customer_id, m.product_name, s.order_date, RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranks
				FROM dannys_diner.sales s
				INNER JOIN dannys_diner.menu m
				ON s.product_id = m.product_id
			    GROUP BY s.customer_id, m.product_name,s.order_date)
				
				SELECT customer_id, product_name, order_date
				FROM ranking
				WHERE ranks = 1
				
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT s.product_id, m.product_name, COUNT(s.product_id) AS count_of_purchase
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
ORDER BY count_of_purchase DESC
LIMIT 1
--The most purchased item on the menu is ramen which was purchased 8 times

-- 5. Which item was the most popular for each customer? **********
with popular_item as (SELECT s.customer_id, s.product_id, m.product_name, COUNT(s.product_id) AS number_of_purchase,
					  RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id)DESC) AS ranks
					FROM dannys_diner.sales s
					JOIN dannys_diner.menu m
					ON s.product_id = m.product_id
					GROUP BY s.customer_id,s.product_id, m.product_name
					ORDER BY s.customer_id)
SELECT customer_id, product_name, number_of_purchase
FROM popular_item
WHERE ranks = 1					

-- 6. Which item was purchased first by the customer after they became a member?
with ranking as(SELECT s.customer_id, me.product_name, s.product_id, m.join_date, s.order_date,
				 RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as ranks
				 FROM dannys_diner.members m
				 JOIN dannys_diner.sales s
				 ON s.customer_id = m.customer_id
				 JOIN dannys_diner.menu me
				 ON s.product_id = me.product_id
				 WHERE s.order_date >= m.join_date
				)
SELECT customer_id, product_name, product_id, join_date, order_date
FROM ranking
where ranks = 1

-- 7. Which item was purchased just before the customer became a member?
with ranking as (SELECT s.customer_id, me.product_name, s.product_id, m.join_date, s.order_date,
				 RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) as ranks
				 FROM dannys_diner.members m
				 JOIN dannys_diner.sales s
				 ON s.customer_id = m.customer_id
				 JOIN dannys_diner.menu me
				 ON s.product_id = me.product_id
				 WHERE s.order_date < m.join_date
				 ORDER BY s.order_date, s.customer_id
				)
SELECT customer_id, product_name, product_id, join_date, order_date
FROM ranking
where ranks = 1

-- 8. What is the total items and amount spent for each member before they became a member?
with table_1 as (SELECT s.customer_id, me.product_name, s.product_id, m.join_date, s.order_date, me.price
				 FROM dannys_diner.members m
				 JOIN dannys_diner.sales s
				 ON s.customer_id = m.customer_id
				 JOIN dannys_diner.menu me
				 ON s.product_id = me.product_id
				 WHERE s.order_date < m.join_date
				 )
SELECT customer_id, COUNT(product_id) as total_items, SUM(price) as total_spent
FROM table_1
GROUP BY customer_id
ORDER BY customer_id

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?


with point_table_1 as (SELECT s.customer_id, me.product_name, me.price, (me.price * 10) as points
					   FROM dannys_diner.sales s
					   FULL JOIN dannys_diner.members m
					   ON s.customer_id = m.customer_id
					   FULL JOIN dannys_diner.menu me
					   ON s.product_id = me.product_id
					   WHERE product_name != 'sushi'),					   

     point_table_2 as (SELECT s.customer_id, me.product_name, me.price, (me.price * 20) as points_2
					   FROM dannys_diner.sales s
					   FULL JOIN dannys_diner.members m
					   ON s.customer_id = m.customer_id
					   FULL JOIN dannys_diner.menu me
					   ON s.product_id = me.product_id
					   WHERE product_name = 'sushi'),
					   
	 point_table_3 as (SELECT customer_id, SUM(points)
					   FROM point_table_1
					   GROUP BY customer_id
					   UNION ALL
					   SELECT customer_id, SUM(points_2)
					   FROM point_table_2
					   GROUP BY customer_id)
					   
					   SELECT customer_id, SUM(sum) as sum_of_points
					   FROM point_table_3
					   GROUP BY customer_id


/*10. In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not 
just sushi - how many points do customer A and B have at the end of January?*/


WITH table_cte AS (SELECT customer_id, 
					join_date, 
					join_date + 6 AS valid_date, 
					'2021-01-31' AS last_date
				    FROM dannys_diner.members
				   )

SELECT 
  s.customer_id, 
  SUM(CASE WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
    		WHEN s.order_date BETWEEN t.join_date AND t.valid_date THEN 2 * 10 * m.price
    		ELSE 10 * m.price END) AS points
FROM dannys_diner.sales s
JOIN table_cte AS t
  ON s.customer_id = t.customer_id
AND s.order_date <= '2021-01-31'
JOIN dannys_diner.menu m
  ON s.product_id = m.product_id
GROUP BY s.customer_id;