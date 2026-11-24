

-- Week 2 Assignment (firstly Run week 1 first because some tables are used again.)


-- Q2.1 Books beaten by adaptation within 4 years
create table author (author_id int primary key, author_name varchar(50));
insert into author values (1, 'Anita Rao'), (2, 'Dev Malhotra'), (3, 'Kiran Sethi'), (4, 'Leela Thomas');

create table book (book_id int primary key, author_id int, title varchar(60), publish_year int);
insert into book values
(101, 1, 'The Monsoon Letters', 2015), (102, 1, 'City of Lanterns', 2018),
(103, 2, 'Code of the Hills', 2012), (104, 3, 'The Last Tea Garden', 2019),
(105, 4, 'Silent Harbour', 2016), (106, 2, 'Paper Kites', 2020);

create table adaptation (book_id int primary key, type varchar(20), title varchar(60), release_year int, rating decimal(4,2));
insert into adaptation values
(101, 'Movie', 'Monsoon Letters', 2017, 8.10), (102, 'Series', 'Lanterns', 2024, 7.90),
(103, 'Movie', 'Hill Code', 2014, 7.00), (104, 'Series', 'Tea Garden', 2022, 8.60),
(105, 'Movie', 'Harbour', 2018, 6.50), (106, 'Movie', 'Kites', 2021, 7.40);

create table book_review (review_id int primary key, book_id int, rating decimal(4,2));
insert into book_review values
(1,101,7),(2,101,8),(3,102,6),(4,102,7),(5,103,8),(6,103,7),(7,103,9),
(8,104,8),(9,104,8),(10,105,6),(11,105,7),(12,106,7),(13,106,7),(14,106,7);

select 
    bk.title as book_title,
    ad.title as adaptation_title,
    ad.release_year as adaptation_year,
    bk.publish_year as publication_year,
    au.author_name,
    cast(round(avg(rv.rating), 2) as decimal(4, 2)) as book_rating,
    ad.rating as adaptation_rating
from book bk
join author au on bk.author_id = au.author_id
join adaptation ad on bk.book_id = ad.book_id
join book_review rv on bk.book_id = rv.book_id
where ad.release_year between bk.publish_year and bk.publish_year + 4
group by bk.title, ad.title, ad.release_year, bk.publish_year, au.author_name, ad.rating
having avg(rv.rating) < ad.rating
order by bk.title;
go


-- Q2.2 Customer order lookup function & proc (These tables are already in week 1.)


create function dbo.fn_format_us_date (@dt datetime)
returns varchar(10)
as
begin
    return convert(varchar(10), @dt, 101);
end;
go

create procedure dbo.sp_customer_orders
    @customer_id varchar(10),
    @order_count int output,
    @total_value decimal(10, 2) output
as
begin
    set nocount on;

    select 
        o.order_id,
        dbo.fn_format_us_date(o.order_date) as order_date_us,
        o.status,
        cast(isnull(sum(oi.qty * oi.unit_price), 0) as int) as order_value
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.customer_id = @customer_id
      and o.status <> 'Cancelled'
    group by o.order_id, o.order_date, o.status
    order by o.order_id;

    select 
        @order_count = count(distinct o.order_id),
        @total_value = isnull(sum(oi.qty * oi.unit_price), 0)
    from orders o
    left join order_items oi on o.order_id = oi.order_id
    where o.customer_id = @customer_id
      and o.status <> 'Cancelled';
end;
go

declare @cnt int, @val decimal(10, 2);
exec dbo.sp_customer_orders 'C01', @cnt output, @val output;
select @cnt as order_count, cast(@val as int) as total_value;

declare @cnt2 int, @val2 decimal(10, 2);
exec dbo.sp_customer_orders 'C99', @cnt2 output, @val2 output;
select @cnt2 as order_count, cast(@val2 as int) as total_value;
go


-- Q2.3 Generate remaining month dates
create table datepro (
    id int primary key,
    Dateint int,
    Datentime varchar(40)
);

insert into datepro values
(101, 20220510, '2022-05-10T09:30:00+05:30'),
(102, 20220227, '2022-02-27T18:45:00+05:30'),
(103, 20220925, '2022-09-25T12:16:00+05:30'),
(104, 20221229, '2022-12-29T07:05:00+05:30'),
(105, 20221228, '2022-12-28T11:29:00+05:30');

create table datepro_data (
    id int,
    Dateint int,
    Datentime varchar(20),
    Dates date
);
go

create procedure sp_dateproc
    @ids varchar(100)
as
begin
    set nocount on;
    truncate table datepro_data;

    with src as (
        select 
            d.id,
            d.Dateint,
            replace(left(d.Datentime, 16), 'T', ' ') as dt_clean,
            cast(cast(d.Dateint as varchar(8)) as date) as d1,
            eomonth(cast(cast(d.Dateint as varchar(8)) as date)) as d2
        from datepro d
        where d.id in (select cast(trim(value) as int) from string_split(@ids, ','))
    ),
    cal as (
        select id, Dateint, dt_clean, d1 as dt, d2 from src
        union all
        select id, Dateint, dt_clean, dateadd(day, 1, dt), d2 from cal where dt < d2
    )
    insert into datepro_data (id, Dateint, Datentime, Dates)
    select id, Dateint, dt_clean, dt
    from cal
    order by id, dt;

    select * from datepro_data order by id, Dates;
end;
go

exec sp_dateproc '101, 102, 104';
go


-- Q2.4 Open elective allotment by gpa & preference
create table StudentDetails (
    StudentId int primary key,
    StudentName varchar(50),
    GPA decimal(4, 2),
    Branch varchar(20),
    Section char(1)
);

insert into StudentDetails values
(159103036, 'Mohit Agarwal', 8.90, 'CCE', 'A'),
(159103037, 'Rohit Agarwal', 5.20, 'CCE', 'A'),
(159103038, 'Shohit Garg', 7.10, 'CCE', 'B'),
(159103039, 'Mrinal Malhotra', 7.90, 'CCE', 'A'),
(159103040, 'Mehreet Singh', 5.60, 'CCE', 'A'),
(159103041, 'Arjun Tehlan', 9.20, 'CCE', 'B');

create table SubjectDetails (
    SubjectId varchar(10) primary key,
    SubjectName varchar(60),
    MaxSeats int,
    RemainingSeats int
);

insert into SubjectDetails values
('PO1491', 'Basics of Political Science', 60, 2),
('PO1492', 'Basics of Accounting', 120, 1),
('PO1493', 'Basics of Financial Markets', 90, 1),
('PO1494', 'Eco philosophy', 60, 1),
('PO1495', 'Automotive Trends', 60, 0);

create table StudentPreference (
    StudentId int references StudentDetails(StudentId),
    SubjectId varchar(10) references SubjectDetails(SubjectId),
    Preference int,
    primary key (StudentId, SubjectId)
);

insert into StudentPreference values
(159103036,'PO1491',1),(159103036,'PO1492',2),(159103036,'PO1493',3),(159103036,'PO1494',4),(159103036,'PO1495',5),
(159103037,'PO1494',1),(159103037,'PO1495',2),(159103037,'PO1492',3),(159103037,'PO1491',4),(159103037,'PO1493',5),
(159103038,'PO1492',1),(159103038,'PO1491',2),(159103038,'PO1494',3),(159103038,'PO1495',4),(159103038,'PO1493',5),
(159103039,'PO1491',1),(159103039,'PO1492',2),(159103039,'PO1495',3),(159103039,'PO1493',4),(159103039,'PO1494',5),
(159103040,'PO1492',1),(159103040,'PO1494',2),(159103040,'PO1491',3),(159103040,'PO1493',4),(159103040,'PO1495',5),
(159103041,'PO1491',1),(159103041,'PO1493',2),(159103041,'PO1492',3),(159103041,'PO1494',4),(159103041,'PO1495',5);

create table Allotments (SubjectId varchar(10), StudentId int);
create table UnallotedStudents (StudentId int);
go

create procedure dbo.sp_allot_subjects
as
begin
    set nocount on;
    truncate table Allotments;
    truncate table UnallotedStudents;

    declare @sid int, @subid varchar(10), @done bit;

    declare st_cur cursor for
        select StudentId from StudentDetails order by GPA desc;

    open st_cur;
    fetch next from st_cur into @sid;

    while @@fetch_status = 0
    begin
        set @done = 0;

        declare pr_cur cursor for
            select SubjectId from StudentPreference where StudentId = @sid order by Preference;

        open pr_cur;
        fetch next from pr_cur into @subid;

        while @@fetch_status = 0 and @done = 0
        begin
            if exists (select 1 from SubjectDetails where SubjectId = @subid and RemainingSeats > 0)
            begin
                update SubjectDetails set RemainingSeats = RemainingSeats - 1 where SubjectId = @subid;
                insert into Allotments (SubjectId, StudentId) values (@subid, @sid);
                set @done = 1;
            end
            fetch next from pr_cur into @subid;
        end

        close pr_cur;
        deallocate pr_cur;

        if @done = 0
            insert into UnallotedStudents (StudentId) values (@sid);

        fetch next from st_cur into @sid;
    end

    close st_cur;
    deallocate st_cur;
end;
go

exec dbo.sp_allot_subjects;
select * from Allotments;
select * from UnallotedStudents;
select * from SubjectDetails;
go


-- Q2.5 Payment posting with validation & error log
-- Payments table is already in week 1.
/*
create table payments (payment_id varchar(10) primary key, order_id int, payment_date date, amount int, method varchar(20));
insert into payments values
('PM01',1001,'2026-03-02',2198,'UPI'),('PM02',1002,'2026-03-03',1000,'Card'),
('PM03',1002,'2026-03-05',999,'Card'),('PM04',1003,'2026-03-10',500,'UPI'),
('PM05',1005,'2026-03-15',3998,'NetBanking'),('PM06',1006,'2026-03-18',1497,'UPI'),
('PM07',1009,'2026-04-02',750,'UPI'),('PM08',1004,'2026-03-12',1499,'Card');
*/

create table error_log (
    log_id int identity(1,1) primary key,
    error_time datetime default getdate(),
    proc_name varchar(50),
    error_number int,
    error_message varchar(200),
    input_values varchar(200)
);
go

create procedure dbo.sp_record_payment
    @payment_id varchar(10),
    @order_id int,
    @amount decimal(10, 2),
    @method varchar(20)
as
begin
    set nocount on;
    declare @st varchar(20), @oval decimal(10, 2), @paid decimal(10, 2);
    declare @raw_in varchar(200) = concat(@payment_id, ',', @order_id, ',', cast(@amount as int), ',', @method);

    begin try
        begin tran;

        select @st = status from orders where order_id = @order_id;
        if @st is null
            throw 50001, 'Order not found', 1;

        if @st = 'Cancelled'
            throw 50002, 'Order is cancelled', 1;

        if @amount <= 0
            throw 50003, 'Amount must be greater than zero', 1;

        select @oval = isnull(sum(qty * unit_price), 0) from order_items where order_id = @order_id;
        select @paid = isnull(sum(amount), 0) from payments where order_id = @order_id;

        if @paid + @amount > @oval
            throw 50004, 'Payment exceeds order value', 1;

        insert into payments (payment_id, order_id, payment_date, amount, method)
        values (@payment_id, @order_id, cast(getdate() as date), @amount, @method);

        commit tran;
    end try
    begin catch
        if @@trancount > 0
            rollback tran;

        insert into error_log (proc_name, error_number, error_message, input_values)
        values ('sp_record_payment', error_number(), error_message(), @raw_in);
    end catch
end;
go

exec dbo.sp_record_payment 'PM09', 1007, 1499, 'Card';
exec dbo.sp_record_payment 'PM10', 1010, 500, 'UPI';
exec dbo.sp_record_payment 'PM11', 1004, 100, 'UPI';
exec dbo.sp_record_payment 'PM12', 1003, 0, 'UPI';
exec dbo.sp_record_payment 'PM13', 1003, 600, 'UPI';
exec dbo.sp_record_payment 'PM14', 1003, 499, 'UPI';

select payment_id, order_id, amount, method from payments where payment_id in ('PM09', 'PM14');
select log_id, proc_name, error_number, error_message, input_values from error_log;
go


-- Q2.6 Department salary ranking
create table emp_salary (
    emp_id int primary key,
    emp_name varchar(30),
    department varchar(30),
    salary int
);

insert into emp_salary values
(1,'Aditi','Engineering',100000), (2,'Bharat','Engineering',100000),
(3,'Chetan','Engineering',90000), (4,'Divya','Engineering',80000),
(5,'Eshan','Engineering',80000), (6,'Farhan','Engineering',70000),
(7,'Gauri','Sales',75000), (8,'Harsh','Sales',72000),
(9,'Ira','Sales',72000), (10,'Jatin','Support',50000),
(11,'Kavya','HR',60000), (12,'Lokesh','HR',60000);

select 
    emp_id,
    emp_name,
    department,
    salary,
    row_number() over (partition by department order by salary desc, emp_id) as row_num,
    rank() over (partition by department order by salary desc) as rnk,
    dense_rank() over (partition by department order by salary desc) as dense_rnk
from emp_salary
order by department, salary desc, emp_id;

select department, emp_name, salary, salary_level
from (
    select department, emp_name, salary,
           dense_rank() over (partition by department order by salary desc) as salary_level
    from emp_salary
) x
where salary_level <= 3
order by department, salary desc, emp_name;
go


-- Q2.7 Book & author summary view
create table Books (BookID int primary key, Title varchar(50));
insert into Books values (1,'Desert Winds'),(2,'River Songs'),(3,'The Glass Fort'),(4,'Night Train'),(5,'Salt and Stone'),(6,'Paper Moons');

create table Authors (AuthorID int primary key, AuthorName varchar(50));
insert into Authors values (1,'Meera Kaul'),(2,'Rohan Sen'),(3,'Tanvi Bose'),(4,'Ishita Roy');

create table BookAuthors (BookID int, AuthorID int);
insert into BookAuthors values (1,1),(2,2),(3,1),(3,3),(4,4),(5,2),(6,2),(6,1);
go

create view vw_book_author as
select 
    b.Title as Booktitle,
    string_agg(a.AuthorName, ', ') within group (order by a.AuthorName) as Authorname,
    string_agg(cast(ac.b_cnt as varchar(10)), ',') within group (order by a.AuthorName) as Book_count
from Books b
join BookAuthors ba on b.BookID = ba.BookID
join Authors a on ba.AuthorID = a.AuthorID
join (select AuthorID, count(*) as b_cnt from BookAuthors group by AuthorID) ac on a.AuthorID = ac.AuthorID
group by b.BookID, b.Title;
go

select * from vw_book_author;
go


-- Q2.8 Revised salary & previous hire comparison view
create table Dept_loc (deptid int primary key, deptname varchar(30), loc varchar(30));
insert into Dept_loc values (1,'HR','Dallas'),(2,'Sales','Chicago'),(3,'Customer service','Chicago'),(4,'IT','Boston'),(5,'Research','Seattle'),(6,'Legal','New York');

create table Employee (Empid int primary key, Full_name varchar(50), Salary decimal(10,2), Hiredate date, deptid int);
insert into Employee values
(1012,'Raji K Nair',35500,'2018-04-09',1),
(1009,'Jeena',12000,'2018-11-17',2),
(1005,'Nidhi R Shetty',10000,'2019-01-16',3),
(1011,'Jiya Shetty',45500,'2019-03-27',4),
(1003,'Arun Kumar Menon',45500,'2019-08-02',5),
(1007,'Farah Ali',30000,'2020-02-10',null),
(1001,'Manoj P Iyer',52000,'2020-07-15',2);
go

create view VW_EMP_DEPT as
select 
    Empid, Full_name, Salary, Inc_Sal, Previous_emp_sal, Hiredate, deptname, loc,
    case 
        when Previous_emp_sal is null then 'No previous employee'
        when Salary > Previous_emp_sal then 'Salary is greater than previously hired employee'
        when Salary < Previous_emp_sal then 'Salary is less than previously hired employee'
        else 'Salary is same as previously hired employee'
    end as message
from (
    select 
        e.Empid,
        case 
            when charindex(' ', trim(e.Full_name)) = 0 then trim(e.Full_name)
            else left(trim(e.Full_name), charindex(' ', trim(e.Full_name)) - 1) + ' ' +
                 right(trim(e.Full_name), charindex(' ', reverse(trim(e.Full_name))) - 1)
        end as Full_name,
        cast(e.Salary as int) as Salary,
        cast(e.Salary * case 
            when d.loc = 'Chicago' then 1.05
            when d.loc = 'Boston' then 1.03
            when d.loc in ('Dallas', 'New York') then 1.10
            else 1.00
        end as int) as Inc_Sal,
        cast(lag(e.Salary) over (order by e.Hiredate) as int) as Previous_emp_sal,
        e.Hiredate,
        isnull(d.deptname, 'NA') as deptname,
        isnull(d.loc, 'NA') as loc
    from Employee e
    left join Dept_loc d on e.deptid = d.deptid
) base;
go

select * from VW_EMP_DEPT order by Hiredate;
go


-- Q2.9 Running total & 3-month moving average
create table monthly_sales (month_start date, region varchar(20), revenue int);
insert into monthly_sales values
('2026-01-01','North',120000),('2026-02-01','North',135000),('2026-03-01','North',128000),
('2026-04-01','North',150000),('2026-05-01','North',160000),('2026-06-01','North',145000),
('2026-01-01','South',90000),('2026-02-01','South',85000),('2026-03-01','South',110000),
('2026-04-01','South',105000),('2026-05-01','South',130000),('2026-06-01','South',140000);

select 
    region,
    month_start,
    revenue,
    sum(revenue) over (partition by region order by month_start rows unbounded preceding) as running_total,
    cast(round(avg(revenue * 1.0) over (partition by region order by month_start rows between 2 preceding and current row), 2) as decimal(12, 2)) as moving_avg_3m,
    cast(round(revenue * 100.0 / sum(revenue) over (partition by region), 2) as decimal(5, 2)) as pct_of_total
from monthly_sales
order by region, month_start;
go


-- Q2.10 Deduplicating customer updates
create table customer_updates (
    load_id int primary key,
    customer_id varchar(10),
    email varchar(50),
    city varchar(30),
    updated_at datetime
);

insert into customer_updates values
(1, 'C01', 'rahul@mail.com', 'Jaipur', '2026-05-01 10:00:00'),
(2, 'C02', 'priya@mail.com', 'Kochi', '2026-05-01 10:05:00'),
(3, 'C01', 'rahul.m@mail.com', 'Jaipur', '2026-05-03 09:00:00'),
(4, 'C03', 'arjun@mail.com', 'Kolkata', '2026-05-02 12:00:00'),
(5, 'C02', 'priya@mail.com', 'Kochi', '2026-05-01 10:05:00'),
(6, 'C01', 'rahul.m@mail.com', 'Delhi', '2026-05-03 09:00:00'),
(7, 'C04', 'fatima@mail.com', 'Mumbai', '2026-05-04 08:30:00'),
(8, 'C03', 'arjun.d@mail.com', 'Kolkata', '2026-05-05 18:45:00');

select customer_id, email, city, updated_at, load_id
from (
    select customer_id, email, city, updated_at, load_id,
           row_number() over (partition by customer_id order by updated_at desc, load_id desc) as rn
    from customer_updates
) dedup
where rn = 1
order by customer_id;

select 
    count(*) as rows_loaded,
    count(distinct customer_id) as rows_kept,
    count(*) - count(distinct customer_id) as rows_removed
from customer_updates;
go


-- Q2.11 Longest login streak per user
create table logins (user_id varchar(10), login_date date);
insert into logins values
('U1','2026-03-01'),('U1','2026-03-02'),('U1','2026-03-03'),
('U1','2026-03-05'),('U1','2026-03-06'),('U1','2026-03-07'),
('U2','2026-03-01'),('U2','2026-03-03'),('U2','2026-03-04'),
('U2','2026-03-05'),('U2','2026-03-06'),('U2','2026-03-10'),
('U3','2026-03-02'),
('U4','2026-03-01'),('U4','2026-03-02'),('U4','2026-03-04'),
('U4','2026-03-05'),('U4','2026-03-08'),('U4','2026-03-09');

select user_id, streak_start, streak_end, streak_days
from (
    select 
        user_id,
        min(login_date) as streak_start,
        max(login_date) as streak_end,
        count(*) as streak_days,
        row_number() over (partition by user_id order by count(*) desc, max(login_date) desc) as rn
    from (
        select user_id, login_date,
               dateadd(day, -row_number() over (partition by user_id order by login_date), login_date) as grp
        from logins
    ) g
    group by user_id, grp
) res
where rn = 1
order by user_id;
go
