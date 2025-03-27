---Natural Join
select name, course_id
from student, takes
where student.ID = takes.ID
order by name;

select name, course_id
from student natural join takes
order by name;

select name, title
from student natural join takes, course
where takes.course_id = course.course_id;

select name, title
from student natural join takes natural join course;

select name, title
from (student natural join takes) join course using (course_id);

select *
from student join takes on student.ID = takes.ID;

select *
from student, takes
where student.ID = takes.ID;

--- Left Outer Join
select *
from student natural left outer join takes;

select ID, name
from student natural left outer join takes
where course_id is null;

---Right outer join
select *
from takes natural right outer join student;

---Full outer join
select *
from (select *
		from student
		where dept_name = 'Comp. Sci.')
		natural full outer join
		(select *
		from takes
		where semester = 'Spring' and year = 2017);

---On and where cluase in join
select *
from student left outer join takes on student.ID = takes.ID;

select *
from student left outer join takes on true
where student.ID = takes.ID;

---Inner join
select *
from student join takes using (ID);

select *
from student inner join takes using (ID);


---View
create view faculty as
	select ID, name, dept_name
	from instructor;

select name
from faculty
where dept_name = 'Biology';

create view departments_total_salary(dept_name, total_salary) as
	select dept_name, sum (salary)
	from instructor
	group by dept_name;
	
--- Using other views
create view physics_fall_2017 as
	select course.course_id, sec_id, building, room_number
	from course, section
	where course.course_id = section.course_id
		and course.dept_name = 'Physics'
		and section.semester = 'Fall'
		and section.year = '2017';

create view physics_fall_2017_watson as
	select course_id, room_number
	from physics_fall_2017
	where building= 'Watson';
	

---Materialized Views 
CREATE MATERIALIZED VIEW student_course_count AS
SELECT s.ID, s.name, COUNT(t.course_id) AS course_count
FROM student s
LEFT JOIN takes t ON s.ID = t.ID
GROUP BY s.ID, s.name;

REFRESH MATERIALIZED VIEW student_course_count;

---Update of a view
insert into faculty 
	values ('30765', 'Green', 'Music');


create view history_instructors as
select *
from instructor
where dept_name= 'History';

insert into history_instructors 
	values ('25566', 'Brown', 'Biology', 100000);

create view history_instructors as
select *
from instructor
where dept_name= 'History'
with check option;

insert into history_instructors 
	values ('25566', 'Brown', 'Biology', 100000);

---Transaction
BEGIN;

INSERT INTO takes (id, course_id, sec_id, semester, year, grade)
VALUES ('98988', 'CS-101', '1', 'Fall', 2017, 'A');

UPDATE student
SET tot_cred = tot_cred + 3
WHERE id = '98988';

COMMIT;

---if there is error in above query we use rollback
rollback;


---check clause

create table section 
   (course_id varchar (8),
	sec_id varchar (8),
	semester varchar (6),
	year numeric (4,0),
	building varchar (15),
	room_number varchar (7),
	time_slot_id varchar (4), 
	primary key (course_id, sec_id, semester, year),
	check (semester in ('Fall', 'Winter', 'Spring', 'Summer')));
	

--- Assigning names to constraints
create table instructor
	(ID varchar(5), 
	 name varchar(20) not null, 
	 dept_name varchar(20), 
	 salary numeric(8,2), constraint minsalary check (salary > 29000),
	 primary key (ID),
	 foreign key (dept_name) references department (dept_name)
		on delete set null
	);

alter table instructor drop constraint minsalary;

--- Integrity Constraint Violation During Transactions
CREATE TABLE person (
    ID char(10),
    name char(40),
    mother char(10),
    father char(10),
    PRIMARY KEY (ID),
    FOREIGN KEY (father) REFERENCES person(ID) DEFERRABLE,
    FOREIGN KEY (mother) REFERENCES person(ID) DEFERRABLE
);


--
BEGIN;
-- Explicitly deferring the constraints if needed
SET CONSTRAINTS ALL DEFERRED;
-- Inserting the son without immediate parents' records
INSERT INTO person (ID, name) VALUES ('3', 'Son');
-- Now inserting the father
INSERT INTO person (ID, name) VALUES ('1', 'Father');
-- And then the mother
INSERT INTO person (ID, name) VALUES ('2', 'Mother');
UPDATE person SET father = '1', mother = '2' WHERE ID = '3';
COMMIT;

---Data types
CREATE TABLE event_details (
    event_id SERIAL PRIMARY KEY,
    event_name VARCHAR(100),
    event_date DATE,
    start_time TIME,
    event_timestamp TIMESTAMP
);

INSERT INTO event_details (event_name, event_date, start_time, event_timestamp) VALUES
('New Year Celebration', '2024-01-01', '00:00:00', CURRENT_TIMESTAMP + INTERVAL '1 year'),
('Project Deadline', '2024-05-15', '17:00:00', CURRENT_TIMESTAMP + INTERVAL '30 days'),
('Morning Meeting', '2024-07-04', '09:00:00', CURRENT_TIMESTAMP + INTERVAL '2 hours'),
('Webinar', '2024-06-01', '14:00:00', '2024-06-01 14:00:00');

---Type conversion
select cast(id as numeric(5)) as inst_id
from instructor
order by inst_id;

select ID, coalesce(salary, 0) as salary
from instructor;


--- User defined types
CREATE TYPE Dollars AS (amount NUMERIC(12,2));
CREATE TYPE Pounds AS (amount NUMERIC(12,2));

create table department
			(dept_name varchar (20),
			 building varchar (15),
			 budget Dollars);

---Domain
create domain person_name as char(20) not null;
create domain DDollars as numeric(12,2) not null;

create domain degree_level varchar(10)
	constraint degree_level_test
		check (value in ('Bachelors', 'Masters', 'Doctorate'));


---Unique key
CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    amount_in_dollars Dollars
);


---Table extensions
create table temp_instructor (like instructor);

create table t1 as
	(select *
	from instructor
	where dept_name = 'Accounting')
with data;

---Index Creation
create index studentID_index on student(ID);

create index dept_index on instructor (dept_name);

drop index studentID_index;

SELECT * FROM pg_indexes
where tablename = 'student';


---Create Users
CREATE USER Amit WITH PASSWORD 'Amit';

CREATE USER Satoshi WITH PASSWORD 'Satoshi';


---Grant privilages to instructor
grant  select 
on  department 
to Amit,  Satoshi;

---revoking
revoke select on department from Amit, Satoshi;

---Role creation
create role instructor;

grant instructor to Amit;

grant select on takes
to instructor;

create role teaching_assistant;
grant teaching_assistant to instructor;

create role dean;
grant instructor to dean;
grant dean to Satoshi;


---Authorization on Views
create view  geo_instructor as
	(select *
	 from instructor
	 where dept_name = 'Geology');

grant select on geo_instructor to Amit;

select * 
from geo_instructor;

grant select on department to Amit with grant option;


revoke select on department from Amit, Satoshi;


