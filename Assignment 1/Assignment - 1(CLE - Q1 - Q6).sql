-- Q1.1: COURSE BATCHES

CREATE DATABASE Edulearn;
USE Edulearn;

CREATE TABLE course_batches
(
    batch_id INT PRIMARY KEY,
    subject_id VARCHAR(5) NOT NULL,
    batch_name VARCHAR(40) NOT NULL,
    start_date DATE NOT NULL,
    capacity INT CHECK (capacity > 0),
    trainer VARCHAR(40) NULL,
    status VARCHAR(10) DEFAULT 'Planned'
);

-- STEP 1: INSERT FOUR ROWS

INSERT INTO course_batches
(batch_id, subject_id, batch_name, start_date, capacity, trainer)
VALUES
(1, 'S01', 'SQL Morning Batch', '2026-04-01', 30, NULL),
(2, 'S02', 'Python Weekend Batch', '2026-04-05', 25, 'Ritu Sharma'),
(3, 'S03', 'Visualization Evening', '2026-05-10', 20, NULL),
(4, 'S01', 'SQL Evening Batch', '2026-03-20', 30, 'Amit Bansal');



BEGIN TRY
    INSERT INTO course_batches
    (batch_id, subject_id, batch_name, start_date, capacity, trainer)
    VALUES
    (5, 'S04', 'Stats Crash Course', '2026-04-15', 0, NULL);
END TRY
BEGIN CATCH
    PRINT 'Invalid capacity. Insert failed.';
END CATCH;


-- STEP 4: TRANSACTION AND ROLLBACK

BEGIN TRANSACTION;

DELETE FROM course_batches
WHERE status = 'Planned';

ROLLBACK TRANSACTION;


-- STEP 5: UPDATE STATUS

UPDATE course_batches
SET status = 'Open'
WHERE start_date <= '2026-04-01';

-- FINAL Q1.1 OUTPUT

SELECT * FROM course_batches ORDER BY batch_id;



-- ============================================
-- Q1.2 + Q1.3: STUDENTS TABLE
-- ============================================

CREATE TABLE students
(
    student_id INT PRIMARY KEY,
    student_name VARCHAR(50),
    gender CHAR(1),
    city VARCHAR(30),
    email VARCHAR(100),
    phone VARCHAR(15),
    dob DATE,
    join_date DATE
);



-- INSERT STUDENT DATA 

INSERT INTO students
(student_id, student_name, gender, city, email, phone, dob, join_date)
VALUES
(101, '  aarav sharma  ', 'M', 'Jaipur',
 'aarav.sharma@gmail.com', '9876543210', '2004-05-12', '2026-01-05'),

(102, 'Diya Patel', 'F', 'Ahmedabad',
 'diya.patel@yahoo.com', NULL, '2003-11-23', '2026-01-10'),

(103, 'Kabir Singh', 'M', 'Delhi',
 NULL, '9812345678', '2004-02-02', '2026-01-18'),

(104, 'Meera Iyer', 'F', 'Chennai',
 'meera.iyer@outlook.com', '9900112233', NULL, '2026-02-03'),

(105, 'rohan VERMA', 'M', 'Jaipur',
 'rohan.verma@gmail.com', '9811122233', '2006-07-30', '2026-02-14'),

(106, 'Sana Khan', 'F', 'Delhi',
 NULL, NULL, NULL, '2026-02-20'),

(107, 'Ishaan Gupta', 'M', 'Pune',
 'ishaan.gupta@gmail.com', '9822001100', '2004-09-08', '2026-03-01'),

(108, 'Ananya Rao', 'F', NULL,
 NULL, NULL, '2003-12-19', '2026-03-06'),

(109, 'Vikram Joshi', 'M', 'Jaipur',
 'vikram.joshi@yahoo.com', '9876501234', '2004-01-25', '2026-03-11'),

(110, 'Neha Kapoor', 'F', 'Mumbai',
 'neha.kapoor@gmail.com', '9000098000', '2005-03-14', '2026-03-20');



 
-- ============================================
-- Q1.2: ADMISSIONS DESK LIST
-- ============================================

-- CALL LIST TABLE

CREATE TABLE call_list
(
    student_id INT,
    student_name VARCHAR(50),
    city VARCHAR(30),
    join_date DATE
);



-- INSERT JAIPUR AND DELHI STUDENTS
-- JOINED BETWEEN FEBRUARY AND MARCH

INSERT INTO call_list
(student_id, student_name, city, join_date)
SELECT
    student_id,
    student_name,
    city,
    join_date
FROM students
WHERE city IN ('Jaipur', 'Delhi')
AND join_date BETWEEN '2026-02-01' AND '2026-03-31';

-- FINAL CALL LIST

SELECT *
FROM call_list
ORDER BY join_date DESC;


-- CAMPAIGN CITIES TABLE

CREATE TABLE campaign_cities
(
    city VARCHAR(30)
);

-- INSERT DISTINCT NON-NULL CITIES

INSERT INTO campaign_cities (city)
SELECT DISTINCT city
FROM students
WHERE city IS NOT NULL;

-- FINAL CITY LIST

SELECT *
FROM campaign_cities
ORDER BY city;


-- ============================================
-- Q1.3: CLEAN STUDENT CONTACT DETAILS
-- ============================================

-- CREATE CLEAN CONTACT TABLE

SELECT
    student_id,

    UPPER(LTRIM(RTRIM(student_name))) AS clean_name,

    CASE
        WHEN email IS NULL THEN 'Not Provided'
        ELSE LEFT(email, CHARINDEX('@', email) - 1)
    END AS email_user,

    CASE
        WHEN email IS NULL THEN 'Not Provided'
        ELSE SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email))
    END AS email_domain,

    CASE
        WHEN phone IS NULL THEN 'Not Provided'
        ELSE CONCAT('XXXXXX', RIGHT(phone, 4))
    END AS masked_phone,

    DATENAME(MONTH, join_date) AS join_month,

    DATEDIFF(DAY, join_date, '2026-10-01') AS days_with_us

INTO student_contact_clean
FROM students;

-- FINAL CLEAN CONTACT TABLE

SELECT *
FROM student_contact_clean
ORDER BY student_id;


-- ==========================================
-- Q1.4 PART A: STUDENT PROFILE STATUS
-- ==========================================

SELECT
    student_id,
    student_name,

    (CASE WHEN email IS NULL THEN 1 ELSE 0 END +
     CASE WHEN phone IS NULL THEN 1 ELSE 0 END +
     CASE WHEN city IS NULL THEN 1 ELSE 0 END +
     CASE WHEN dob IS NULL THEN 1 ELSE 0 END) AS missing_fields,

    CASE
        WHEN email IS NULL AND phone IS NULL
            THEN 'Contact Missing'

        WHEN email IS NOT NULL
         AND phone IS NOT NULL
         AND city IS NOT NULL
         AND dob IS NOT NULL
            THEN 'Complete'

        ELSE 'Partially Complete'
    END AS profile_status

INTO student_profile_status
FROM students;

SELECT *
FROM student_profile_status
ORDER BY student_id;





-- ==========================================
-- Q1.4 PART B: CREATE FEE PAYMENTS TABLE
-- ==========================================

CREATE TABLE fee_payments
(
    payment_id VARCHAR(5) PRIMARY KEY,
    student_id INT,
    subject_id VARCHAR(5),
    payment_date DATE,
    amount INT NULL,
    status VARCHAR(15)
);

INSERT INTO fee_payments
(payment_id, student_id, subject_id, payment_date, amount, status)
VALUES
('P01',101,'S01','2026-01-06',4000,'Success'),
('P02',101,'S02','2026-01-20',5000,'Success'),
('P03',102,'S01','2026-01-11',4000,'Failed'),
('P04',102,'S01','2026-01-12',4000,'Success'),
('P05',103,'S02','2026-01-19',2500,'Success'),
('P06',103,'S03','2026-02-01',3500,'Success'),
('P07',104,'S01','2026-02-04',4000,'Success'),
('P08',105,'S02','2026-02-15',5000,'Success'),
('P09',105,'S04','2026-02-16',NULL,'Pending'),
('P10',103,'S02','2026-02-19',2500,'Success'),
('P11',107,'S01','2026-03-02',4000,'Success'),
('P12',107,'S02','2026-03-03',5000,'Refunded'),
('P13',108,'S03','2026-03-06',3500,'Success'),
('P14',109,'S01','2026-03-12',4000,'Success'),
('P15',110,'S05','2026-03-21',4500,'Success');


-- PAYMENT CLASSIFICATION

SELECT
    payment_id,
    student_id,
    amount,
    status,

    CASE
        WHEN amount IS NULL THEN 'Amount Missing'
        WHEN status <> 'Success' THEN 'Not Collected'
        ELSE 'Collected'
    END AS payment_class

INTO payment_classification
FROM fee_payments;

SELECT *
FROM payment_classification
ORDER BY payment_id;


-- ==========================================
-- Q1.4 PART C: PAYMENT AVERAGE CHECK
-- ==========================================

SELECT
    CAST(AVG(CAST(amount AS DECIMAL(10,2)))
         AS DECIMAL(10,2)) AS avg_amount_correct,

    CAST(AVG(CAST(ISNULL(amount,0) AS DECIMAL(10,2)))
         AS DECIMAL(10,2)) AS avg_amount_wrong

INTO payment_average_check
FROM fee_payments;

SELECT *
FROM payment_average_check;




-- ==========================================
-- Q1.5: CREATE SUBJECTS TABLE
-- ==========================================

CREATE TABLE subjects
(
    subject_id VARCHAR(5) PRIMARY KEY,
    subject_name VARCHAR(50),
    fee INT,
    max_seats INT
);

INSERT INTO subjects
(subject_id, subject_name, fee, max_seats)
VALUES
('S01','SQL Fundamentals',4000,30),
('S02','Python Programming',5000,30),
('S03','Data Visualization',3500,20),
('S04','Statistics',3000,25),
('S05','Cloud Basics',4500,20),
('S06','Machine Learning',6000,15);


-- ==========================================
-- CREATE ENROLLMENTS TABLE
-- ==========================================

CREATE TABLE enrollments
(
    enrollment_id VARCHAR(5) PRIMARY KEY,
    student_id INT,
    subject_id VARCHAR(5),
    enroll_date DATE
);

INSERT INTO enrollments
(enrollment_id, student_id, subject_id, enroll_date)
VALUES
('E01',101,'S01','2026-01-06'),
('E02',101,'S02','2026-01-06'),
('E03',102,'S01','2026-01-11'),
('E04',103,'S02','2026-01-19'),
('E05',103,'S03','2026-02-01'),
('E06',104,'S01','2026-02-04'),
('E07',105,'S02','2026-02-15'),
('E08',105,'S04','2026-02-15'),
('E09',107,'S01','2026-03-02'),
('E10',107,'S02','2026-03-02'),
('E11',108,'S03','2026-03-06'),
('E12',109,'S01','2026-03-12'),
('E13',110,'S05','2026-03-21'),
('E14',112,'S02','2026-03-25');


-- ==========================================
-- CALCULATE SUBJECT DEMAND
-- ==========================================

SELECT
    s.subject_id,
    s.subject_name,

    COUNT(st.student_id) AS enrolled_students,

    s.max_seats - COUNT(st.student_id) AS seats_left,

    CASE
        WHEN COUNT(st.student_id) >= 4 THEN 'High'
        WHEN COUNT(st.student_id) BETWEEN 2 AND 3 THEN 'Medium'
        WHEN COUNT(st.student_id) = 1 THEN 'Low'
        ELSE 'No Demand'
    END AS demand_level

INTO subject_demand

FROM subjects s

LEFT JOIN enrollments e
ON s.subject_id = e.subject_id

LEFT JOIN students st
ON e.student_id = st.student_id

GROUP BY
    s.subject_id,
    s.subject_name,
    s.max_seats;


-- FINAL RESULT

SELECT *
FROM subject_demand
ORDER BY enrolled_students DESC, subject_id;



-- ==========================================
-- Q1.6 PART A: MONTHLY REVENUE
-- ==========================================

SELECT
    CONVERT(VARCHAR(7), payment_date, 120) AS pay_month,

    SUM(CASE
        WHEN status = 'Success' THEN 1
        ELSE 0
    END) AS successful_payments,

    SUM(CASE
        WHEN status = 'Success' THEN amount
        ELSE 0
    END) AS total_revenue,

    AVG(CASE
        WHEN status = 'Success'
        THEN CAST(amount AS DECIMAL(10,2))
    END) AS avg_payment,

    SUM(CASE
        WHEN status <> 'Success' THEN 1
        ELSE 0
    END) AS other_payments

INTO monthly_revenue

FROM fee_payments

GROUP BY CONVERT(VARCHAR(7), payment_date, 120)

HAVING SUM(CASE
    WHEN status = 'Success' THEN amount
    ELSE 0
END) >= 15000;


-- FINAL MONTHLY REVENUE TABLE

SELECT *
FROM monthly_revenue
ORDER BY pay_month;


-- ==========================================
-- Q1.6 PART B: REVENUE BY SUBJECT
-- ==========================================

SELECT
    s.subject_name,

    SUM(fp.amount) AS total_revenue

INTO subject_revenue

FROM subjects s

INNER JOIN fee_payments fp
ON s.subject_id = fp.subject_id

WHERE fp.status = 'Success'

GROUP BY s.subject_name

HAVING SUM(fp.amount) > 8000;


-- FINAL SUBJECT REVENUE TABLE

SELECT *
FROM subject_revenue
ORDER BY total_revenue DESC;


