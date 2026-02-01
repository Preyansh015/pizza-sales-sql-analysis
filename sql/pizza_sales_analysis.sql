/*
Project: Pizza Sales Data Analysis
Author: Preyansh Raut
Description:
This SQL script analyzes pizza sales data to extract business insights
such as total revenue, order trends, popular pizzas, size preferences,
and category-wise performance.
*/


-- ===============================
-- TABLE CREATION
-- ===============================

CREATE TABLE orders (
    order_id INT NOT NULL PRIMARY KEY,
    order_date DATE NOT NULL,
    order_time TIME NOT NULL
);

CREATE TABLE order_details (
    order_details_id INT NOT NULL PRIMARY KEY,
    order_id INT NOT NULL,
    pizza_id TEXT NOT NULL,
    quantity INT NOT NULL
);


-- ===============================
-- 1. Total number of orders placed
-- ===============================

SELECT 
    COUNT(order_id) AS total_orders
FROM orders;


-- ==========================================
-- 2. Total revenue generated from pizza sales
-- ==========================================

SELECT 
    ROUND(SUM(od.quantity * p.price), 2) AS total_revenue
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id;


-- ===============================
-- 3. Highest-priced pizza
-- ===============================

SELECT 
    pt.name AS pizza_name,
    p.price
FROM pizzas p
JOIN pizza_types pt 
    ON p.pizza_type_id = pt.pizza_type_id
ORDER BY p.price DESC
LIMIT 1;


-- ===================================
-- 4. Most common pizza size ordered
-- ===================================

SELECT 
    p.size,
    SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p 
    ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY total_quantity DESC
LIMIT 1;


-- ==================================================
-- 5. Top 5 most ordered pizza types by quantity
-- ==================================================

SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity) AS total_quantity
FROM pizza_types pt
JOIN pizzas p 
    ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od 
    ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 5;


-- ==========================================================
-- 6. Total quantity of pizzas ordered by each category
-- ==========================================================

SELECT 
    pt.category,
    SUM(od.quantity) AS total_quantity
FROM pizza_types pt
JOIN pizzas p 
    ON pt.pizza_type_id = p.pizza_type_id
JOIN order_details od 
    ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY total_quantity DESC;


-- ==========================================
-- 7. Distribution of orders by hour of the day
-- ==========================================

SELECT 
    HOUR(order_time) AS order_hour,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY order_hour
ORDER BY order_hour;


-- ==================================================
-- 8. Category-wise distribution of pizzas (count)
-- ==================================================

SELECT 
    category,
    COUNT(name) AS total_pizza_types
FROM pizza_types
GROUP BY category;


-- =====================================================
-- 9. Average number of pizzas ordered per day
-- =====================================================

SELECT 
    ROUND(AVG(daily_quantity), 0) AS avg_pizzas_per_day
FROM (
    SELECT 
        o.order_date,
        SUM(od.quantity) AS daily_quantity
    FROM orders o
    JOIN order_details od 
        ON o.order_id = od.order_id
    GROUP BY o.order_date
) AS daily_orders;


-- ==================================================
-- 10. Top 3 pizza types based on revenue
-- ==================================================

SELECT 
    pt.name AS pizza_name,
    SUM(od.quantity * p.price) AS revenue
FROM pizza_types pt
JOIN pizzas p 
    ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od 
    ON od.pizza_id = p.pizza_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 3;


-- ==========================================================
-- 11. Percentage contribution of each category to revenue
-- ==========================================================

SELECT 
    pt.category,
    ROUND(
        SUM(od.quantity * p.price) /
        (SELECT SUM(od2.quantity * p2.price)
         FROM order_details od2
         JOIN pizzas p2 
            ON od2.pizza_id = p2.pizza_id) * 100,
        2
    ) AS revenue_percentage
FROM pizza_types pt
JOIN pizzas p 
    ON p.pizza_type_id = pt.pizza_type_id
JOIN order_details od 
    ON od.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY revenue_percentage DESC;


-- ==========================================
-- 12. Cumulative revenue generated over time
-- ==========================================

SELECT 
    order_date,
    SUM(revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM (
    SELECT 
        o.order_date,
        SUM(od.quantity * p.price) AS revenue
    FROM orders o
    JOIN order_details od 
        ON o.order_id = od.order_id
    JOIN pizzas p 
        ON od.pizza_id = p.pizza_id
    GROUP BY o.order_date
) AS daily_sales;


-- ==============================================================
-- 13. Top 3 pizza types by revenue for each pizza category
-- ==============================================================

SELECT 
    name,
    revenue
FROM (
    SELECT 
        category,
        name,
        revenue,
        RANK() OVER (
            PARTITION BY category 
            ORDER BY revenue DESC
        ) AS rank_in_category
    FROM (
        SELECT 
            pt.category,
            pt.name,
            SUM(od.quantity * p.price) AS revenue
        FROM pizza_types pt
        JOIN pizzas p 
            ON pt.pizza_type_id = p.pizza_type_id
        JOIN order_details od 
            ON od.pizza_id = p.pizza_id
        GROUP BY pt.category, pt.name
    ) AS category_revenue
) AS ranked_pizzas
WHERE rank_in_category <= 3;
