/*** Data cleaning ***/

-- Return all tables for refernece 

SELECT * FROM departments
;
SELECT * FROM products
;
SELECT * FROM aisles
;
SELECT * FROM order_to_product_map
;
SELECT * FROM orders
;
SELECT * FROM household_characteristics
;
SELECT * FROM users
;
SELECT * FROM user_last_order
;


-- Test and update organic column with correct values in products table

SELECT
	product_name
    , IF(lower(product_name) LIKE '%organic%', 1,0) organic
FROM products
;
/*
UPDATE products
SET organic = IF(lower(product_name) LIKE '%organic%', 1,0)
WHERE organic IS NULL;
*/

-- Update table user_last_order column order_date from VARCHAR to DATE
/*
UPDATE user_last_order
SET order_date = STR_TO_DATE(order_date, '%c/%e/%Y')
WHERE order_date IS NOT NULL;

ALTER TABLE user_last_order
MODIFY order_date  DATE;
*/

-- Update table users to have its foriegn key
/*
ALTER TABLE users
ADD FOREIGN KEY(user_id)
	References household_characteristics(user_id)
;
*/

-- Calculate order date for each individual order
SELECT 
	o1.user_id
    , o1.order_number 
    , days_since_prior_order
    , SUM(days_since) running_num_of_days
    , order_date last_date
    , IFNULL(DATE_ADD(order_date, INTERVAL - SUM(days_since) DAY), order_date) order_date
FROM orders o1
	LEFT JOIN user_last_order ulo
		ON ulo.user_id=o1.user_id
	LEFT JOIN (
			SELECT
				user_id
                , order_number
                , SUM(days_since_prior_order) days_since
			FROM orders o2
			GROUP BY user_id, order_number
            ) dc
		ON o1.user_id=dc.user_id 
			AND o1.order_number < dc.order_number
GROUP BY
	o1.user_id
    , order_number
    , days_since_prior_order
    , order_date
ORDER BY user_id, order_number DESC
;



/*** Output summary table ***/

SELECT 
	o1.user_id
    , o1.order_number 
    , o1.order_id
    , IFNULL(DATE_ADD(order_date, INTERVAL - SUM(days_since) DAY), order_date) order_date
    , DAYNAME(IFNULL(DATE_ADD(order_date, INTERVAL - SUM(days_since) DAY), order_date)) order_dow
    , order_hour_of_day
    , days_since_prior_order
    , ot.product_id
    , product_name
    , add_to_cart_order
    , reordered
    , organic
    , aisle
    , department
    , household_income
    , number_in_household
    , address1
    , address2
    , city
    , state
    , zip
FROM orders o1
	LEFT JOIN user_last_order ulo
		ON ulo.user_id=o1.user_id
	LEFT JOIN (
			SELECT
				user_id
                , order_number
                , SUM(days_since_prior_order) days_since
			FROM orders o2
			GROUP BY user_id, order_number
            ) dc
		ON o1.user_id=dc.user_id 
			AND o1.order_number < dc.order_number
	LEFT JOIN users u
		ON u.user_id=o1.user_id
	LEFT JOIN household_characteristics hc
		ON o1.user_id=hc.user_id
	LEFT JOIN order_to_product_map ot
		ON o1.order_id=ot.order_id
	LEFT JOIN products p
		ON ot.product_id=p.product_id
	LEFT JOIN aisles a
		ON p.aisle_ID=a.aisle_id
	LEFT JOIN departments d
		ON p.department_id=d.department_id
GROUP BY
	o1.user_id
    , o1.order_number 
    , o1.order_id
    , DAYNAME(order_dow)
    , order_hour_of_day
    , order_dow
    , days_since_prior_order
    , ot.product_id
    , product_name
    , add_to_cart_order
    , reordered
    , organic
    , aisle
    , department
    , household_income
    , number_in_household
    , address1
    , address2
    , city
    , state
    , zip
ORDER BY user_id, order_number DESC
;
