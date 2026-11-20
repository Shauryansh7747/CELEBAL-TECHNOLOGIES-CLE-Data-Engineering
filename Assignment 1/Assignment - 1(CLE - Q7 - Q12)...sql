---Q1.7. Find Unmatched Students, Customers and Orders

USE EduLearnDB;

CREATE TABLE store_customers
(
    customer_id VARCHAR(5) PRIMARY KEY,
    customer_name VARCHAR(50),
    city VARCHAR(30)
);

INSERT INTO store_customers
(customer_id, customer_name, city)
VALUES
('C01', 'Rahul Mehta', 'Jaipur'),
('C02', 'Priya Nair', 'Kochi'),
('C03', 'Arjun Das', 'Kolkata'),
('C04', 'Fatima Sheikh', 'Mumbai'),
('C05', 'Karan Malhotra', 'Delhi');

SELECT * FROM store_customers;

CREATE TABLE store_orders
(
    order_id VARCHAR(5) PRIMARY KEY,
    customer_id VARCHAR(5) NULL,
    order_date DATE,
    amount INT
);

INSERT INTO store_orders
(order_id, customer_id, order_date, amount)
VALUES
('O1001', 'C01', '2026-03-01', 1200),
('O1002', 'C02', '2026-03-02', 850),
('O1003', 'C01', '2026-03-05', 430),
('O1004', 'C07', '2026-03-06', 999),
('O1005', 'C04', '2026-03-08', 2100),
('O1006', NULL, '2026-03-09', 300);

SELECT * FROM store_orders;

---- Query 1: Students with no enrollment

SELECT
    s.student_id,
    s.student_name,
    s.city

FROM students s

WHERE NOT EXISTS
(
    SELECT 1
    FROM enrollments e
    WHERE e.student_id = s.student_id
);

---- Query 2: Customers with no orders

SELECT
    c.customer_id,
    c.customer_name,
    c.city

FROM store_customers c

LEFT JOIN store_orders o
    ON c.customer_id = o.customer_id

WHERE o.order_id IS NULL;

---------Query 3: Orders with invalid customer

SELECT
    o.order_id,
    o.customer_id,
    o.amount,

    CASE
        WHEN o.customer_id IS NULL
            THEN 'Guest order - no customer'

        ELSE 'Customer not found'
    END AS issue

FROM store_orders o

LEFT JOIN store_customers c
    ON o.customer_id = c.customer_id

WHERE c.customer_id IS NULL;

--Q1.8. Order Summary Report Across Five Tables

CREATE TABLE customers
(
    customer_id VARCHAR(5) PRIMARY KEY,
    customer_name VARCHAR(50),
    city VARCHAR(30),
    signup_date DATE
);

INSERT INTO customers
(customer_id, customer_name, city, signup_date)
VALUES
('C01', 'Rahul Mehta', 'Jaipur', '2025-11-02'),
('C02', 'Priya Nair', 'Kochi', '2025-12-15'),
('C03', 'Arjun Das', 'Kolkata', '2026-01-08'),
('C04', 'Fatima Sheikh', 'Mumbai', '2026-01-20'),
('C05', 'Karan Malhotra', 'Delhi', '2026-02-11'),
('C06', 'Sneha Kulkarni', 'Pune', '2026-02-25');

SELECT * FROM customers;

CREATE TABLE products
(
    product_id VARCHAR(5) PRIMARY KEY,
    product_name VARCHAR(50),
    category VARCHAR(30),
    unit_price INT
);

INSERT INTO products
(product_id, product_name, category, unit_price)
VALUES
('P1', 'Wireless Mouse', 'Electronics', 799),
('P2', 'USB-C Hub', 'Electronics', 1999),
('P3', 'Notebook A5', 'Stationery', 120),
('P4', 'Gel Pen Pack', 'Stationery', 250),
('P5', 'Desk Lamp', 'Home', 1499),
('P6', 'Water Bottle', 'Home', 499);

CREATE TABLE orders
(
    order_id INT PRIMARY KEY,
    customer_id VARCHAR(5),
    order_date DATE,
    status VARCHAR(20)
);

CREATE TABLE order_items
(
    order_id INT,
    product_id VARCHAR(5),
    qty INT,
    unit_price INT
);

INSERT INTO order_items
(order_id, product_id, qty, unit_price)
VALUES
(1001, 'P1', 2, 799),
(1001, 'P3', 5, 120),
(1002, 'P2', 1, 1999),
(1003, 'P4', 2, 250),
(1003, 'P6', 1, 499),
(1004, 'P5', 1, 1499),
(1005, 'P1', 1, 799),
(1005, 'P2', 1, 1999),
(1005, 'P3', 10, 120),
(1006, 'P6', 3, 499),
(1007, 'P5', 1, 1499),
(1008, 'P4', 4, 250);

CREATE TABLE payments
(
    payment_id VARCHAR(5) PRIMARY KEY,
    order_id INT,
    payment_date DATE,
    amount INT,
    method VARCHAR(20)
);

INSERT INTO payments
(payment_id, order_id, payment_date, amount, method)
VALUES
('PM01', 1001, '2026-03-02', 2198, 'UPI'),
('PM02', 1002, '2026-03-03', 1000, 'Card'),
('PM03', 1002, '2026-03-05', 999, 'Card'),
('PM04', 1003, '2026-03-10', 500, 'UPI'),
('PM05', 1005, '2026-03-15', 3998, 'NetBanking'),
('PM06', 1006, '2026-03-18', 1497, 'UPI'),
('PM07', 1009, '2026-04-02', 750, 'UPI'),
('PM08', 1004, '2026-03-12', 1499, 'Card');

--Query: Order Summary ReporT

SELECT
    o.order_id,
    c.customer_name,
    o.order_date,
    o.status,

    ISNULL(i.item_count, 0) AS item_count,
    ISNULL(i.order_value, 0) AS order_value,
    ISNULL(p.paid_amount, 0) AS paid_amount,

    ISNULL(i.order_value, 0)
        - ISNULL(p.paid_amount, 0) AS balance,

    CASE
        WHEN ISNULL(p.paid_amount, 0)
             >= ISNULL(i.order_value, 0)
            THEN 'Paid'

        WHEN ISNULL(p.paid_amount, 0) > 0
            THEN 'Partially Paid'

        ELSE 'Unpaid'
    END AS payment_status

FROM orders o

INNER JOIN customers c
    ON o.customer_id = c.customer_id

LEFT JOIN
(
    SELECT
        order_id,
        SUM(qty) AS item_count,
        SUM(qty * unit_price) AS order_value
    FROM order_items
    GROUP BY order_id
) i
    ON o.order_id = i.order_id

LEFT JOIN
(
    SELECT
        order_id,
        SUM(amount) AS paid_amount
    FROM payments
    GROUP BY order_id
) p
    ON o.order_id = p.order_id

ORDER BY o.order_id;s

-- Q1.9. Reconcile Orders with Payments

----  quey - payment_reconciliation 

SELECT
    COALESCE(o.order_id, p.order_id) AS order_id,
    o.order_status,
    o.order_value,
    ISNULL(p.paid_amount, 0) AS paid_amount,

    CASE
        WHEN o.order_id IS NULL
            THEN 'Unknown Order'

        WHEN o.order_status = 'Cancelled'
             AND p.order_id IS NOT NULL
            THEN 'Refund Required'

        WHEN o.order_status <> 'Cancelled'
             AND p.order_id IS NULL
            THEN 'Payment Missing'

        WHEN p.paid_amount < o.order_value
            THEN 'Short Paid'
    END AS recon_status

FROM
(
    SELECT
        o.order_id,
        o.status AS order_status,
        SUM(ISNULL(oi.qty * oi.unit_price, 0)) AS order_value
    FROM orders o
    LEFT JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.order_id, o.status
) o

FULL OUTER JOIN
(
    SELECT
        order_id,
        SUM(amount) AS paid_amount
    FROM payments
    GROUP BY order_id
) p
    ON o.order_id = p.order_id

WHERE
       o.order_id IS NULL
    OR (o.order_status = 'Cancelled' AND p.order_id IS NOT NULL)
    OR (o.order_status <> 'Cancelled' AND p.order_id IS NULL)
    OR (o.order_status <> 'Cancelled'
        AND p.order_id IS NOT NULL
        AND p.paid_amount < o.order_value)

ORDER BY order_id;

--Q1.10. Employee Directory with Managers and Departments 

CREATE TABLE employees
(
    emp_id VARCHAR(5) PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT NULL,
    manager_id VARCHAR(5) NULL,
    salary INT,
    hire_date DATE
);

INSERT INTO employees
(emp_id, emp_name, dept_id, manager_id, salary, hire_date)
VALUES
('E01', 'Asha Verma', 10, NULL, 150000, '2018-04-01'),
('E02', 'Ravi Kumar', 20, 'E01', 95000, '2019-06-15'),
('E03', 'Meena Pillai', 20, 'E02', 72000, '2021-01-10'),
('E04', 'John Mathew', 20, 'E02', 72000, '2022-03-01'),
('E05', 'Sara Ali', 30, 'E01', 98000, '2019-09-20'),
('E06', 'Vivek Rao', 30, 'E05', 64000, '2023-02-14'),
('E07', 'Pooja Shah', 30, 'E05', 58000, '2024-07-01'),
('E08', 'Nikhil Jain', 20, 'E03', 55000, '2025-01-06'),
('E09', 'Tara Menon', 40, 'E01', 88000, '2020-11-11'),
('E10', 'Imran Qureshi', NULL, 'E01', 61000, '2025-08-18');

CREATE TABLE departments
(
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

INSERT INTO departments
(dept_id, dept_name, location)
VALUES
(10, 'Leadership', 'Jaipur'),
(20, 'Engineering', 'Bengaluru'),
(30, 'Analytics', 'Pune'),
(40, 'Finance', 'Mumbai'),
(50, 'Legal', 'Delhi');


---Part A – Employee Directory

SELECT
    e.emp_id,
    e.emp_name,
    ISNULL(m.emp_name, 'No Manager') AS manager_name,
    ISNULL(d.dept_name, 'Not Assigned') AS dept_name,
    ISNULL(d.location, 'Not Assigned') AS location
FROM employees e
LEFT JOIN employees m
    ON e.manager_id = m.emp_id
LEFT JOIN departments d
    ON e.dept_id = d.dept_id
ORDER BY e.emp_id;

-----Part B – Departments with No Employees

SELECT
    d.dept_id,
    d.dept_name,
    d.location
FROM employees e
RIGHT JOIN departments d
    ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

-----Q1.11. Salary Benchmarks Using Subqueries

----Part A – Find 4th Highest Distinct SalarY

SELECT MAX(salary) AS fourth_highest_salary
FROM employees
WHERE salary < (
    SELECT MAX(salary)
    FROM employees
    WHERE salary < (
        SELECT MAX(salary)
        FROM employees
        WHERE salary < (
            SELECT MAX(salary)
            FROM employees
        )
    )
);

------Part B – Employees Earning More Than Department Average

SELECT
    e.emp_name,
    e.dept_id,
    e.salary,
    CAST((
        SELECT AVG(CAST(e2.salary AS DECIMAL(10,2)))
        FROM employees e2
        WHERE e2.dept_id = e.dept_id
    ) AS DECIMAL(10,2)) AS dept_avg_salary
FROM employees e
WHERE e.dept_id IS NOT NULL
AND e.salary > (
    SELECT AVG(CAST(e2.salary AS DECIMAL(10,2)))
    FROM employees e2
    WHERE e2.dept_id = e.dept_id
)
ORDER BY e.dept_id, e.salary DESC;

-----Part C – Find Managers and Count Direct Reports

SELECT
    e.emp_id,
    e.emp_name,
    (
        SELECT COUNT(*)
        FROM employees e2
        WHERE e2.manager_id = e.emp_id
    ) AS direct_reports
FROM employees e
WHERE EXISTS (
    SELECT 1
    FROM employees e2
    WHERE e2.manager_id = e.emp_id
)
ORDER BY e.emp_id;

------Q1.12. Compare CRM and Billing Customer Lists

CREATE TABLE crm_customers
(
    customer_id VARCHAR(5),
    email VARCHAR(100)
);

INSERT INTO crm_customers (customer_id, email)
VALUES
('C01', 'rahul.mehta@mail.com'),
('C02', 'priya.nair@mail.com'),
('C02', 'priya.nair@mail.com'),
('C03', 'arjun.das@mail.com'),
('C04', 'fatima.s@mail.com');

CREATE TABLE billing_customers
(
    customer_id VARCHAR(5),
    email VARCHAR(100)
);

INSERT INTO billing_customers (customer_id, email)
VALUES
('C02', 'priya.nair@mail.com'),
('C04', 'fatima.s@mail.com'),
('C05', 'karan.m@mail.com'),
('C06', 'sneha.k@mail.com');

----Part A – Customers Present in Both Systems

SELECT customer_id, email
FROM crm_customers

INTERSECT

SELECT customer_id, email
FROM billing_customers;

------Part B – Customers Only in CRM

SELECT customer_id, email
FROM crm_customers

EXCEPT

SELECT customer_id, email
FROM billing_customers;

-----Part C – Customers Only in Billing

SELECT customer_id, email
FROM billing_customers

EXCEPT

SELECT customer_id, email
FROM crm_customers;

----------Part D – Compare UNION and UNION ALL

SELECT
    (
        SELECT COUNT(*)
        FROM
        (
            SELECT customer_id, email
            FROM crm_customers

            UNION

            SELECT customer_id, email
            FROM billing_customers
        ) AS U
    ) AS union_rows,

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT customer_id, email
            FROM crm_customers

            UNION ALL

            SELECT customer_id, email
            FROM billing_customers
        ) AS UA
    ) AS union_all_rows;