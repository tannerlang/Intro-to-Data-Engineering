---CHAPTER 4 SQL PRACTICE
										--JOIN EXPRESSIONS--
										
--Take two relations and return as a result another relation.
--Requires that tuples in the two relations match under some condition.
	--Must specify the attributes you want present in the result.
--Typically used as subquery expressions in the from clause.

				--NATURAL JOIN--
--Compute the set of courses each student has taken:
select name, course_id
from student, takes
where student.ID = takes.ID;

--Same Query with Natural Join:
select name, course_id
from student natural join takes;

--List names of students with the titles of courses they have taken:
select name, title
from student natural join takes, course
where takes.course_id = course.course_id;

--Natural Join with Using Clause
		--Avoids danger of equating attributes erroneously, and requires a list of attribute names to be specified.
select name, title
from (student natural join takes) join course using (course_id);

--On condition
--on condition below specifies that a tuple from student matches a tuple from takes if their id's are equal.
select*
from student join takes on student.ID = takes.ID

				--OUTER JOIN--
--Avoids loss of info.
--Computes the join and then adds tuples from one relation that does not match tuples in the other relation to result.
	--left outer join, right outer join, and full outer join.

--Left Outer Join:
--List all students along with the courses they have taken.
select * 
from student natural left outer join takes;

--Find all students who have not taken a course:
select ID
from student natural left outer join takes
where course_id is null;

--Right Outer Join
	--Symmetric to the left outer join
--List all students along with the courses that they have taken:
select * 
from takes natural right outer join student;

--Full Outer Join:
--List all studeents in comp .sci with course sections that they have take in spring 2017.
select* 
from(select*
	from student
	where dept_name = 'Comp. Sci.')
	natural full outer join
	(select * 
	from takes
	where semester = 'Spring' and year = 2017);

--On clause with outer joins
select * 
from student left outer join takes on student.ID = takes.ID;


				--INNER JOIN--
--Default join type.
select * 
from student join takes using(ID);




													--VIEWS------------REVIEW
													
--Mechanism to hide certain data from the view of certain users.
--View: Any relation that is not of the conceptual model but is made visible to a user as a virtual relation.

--create view v as <query>
--View of instructors without their salary.
create view faculty as
	select ID, name, dept_name
	from instructor;
--Finds all instructors in the biology dept.
	select name
	from faculty
	where dept_name = 'Biology';

--Specify attribute names of view: (finds sum of all salaries in each dept.)
create view departments_total_salary(dept_name, total_salary) as
	select dept_name, sum(salary)
	from instructor
	group by dept_name;


					--Views Defined Using Other Views
--View that lists all course sections offered by Physics dept in fall 2017 semester 
--with building and room number of each section.
create view physics_fall_2017 as
	select course.course_id, sec_id, building, room_number
	from course, section
	where course.course_id = section.course_id
	and course.dept_name = 'Physics'
	and section.semester = 'Fall'
	and section.year = '2017';

--Create view that lists course id and room num of all physics courses offered in fall 2017 in watson building.
create view physics_fall_2017_watson as
	select course_id, room_number
	from physics_fall_2017
	where building = 'Watson';

					--Materialized Views
--Some DB systesm allow view relations to be physically stored.
	--Physical copy created when the vew is defined
	--This is called Materialized Views
--Materialized views can become out of date if relations used in the query for the view are updated.
	--Need to maintain the view by keeping it up to date

--Materialized view to list students and the number of courses they have taken.
create materialized view student_course_count as
	select s.ID, s.name, count(t.course_id) as course_count
	from student s
	left join takes t on s.id = t.id
	group by s.id, s.name;

					--Update the View
--Add a new tuple to faculty view from earlier.
insert into faculty
	values('30765', 'Green', 'English');

													--TRANSACTION--
													
--Consists of a sequence of query and or update statements and is a unit of work.
--Transaction begins implicitly when an SQL statement is executed.
--Transaction must end with:
	--Commit Work: Updates from the transaction become permanent in the database.
	--Rollback work: All updates performed by the SQL statements in the transaction are undone.
--Atomic Transaction either fully executed or rolled back if never occured.

--Enroll student in a new course 'CS-101' and update the students total credits in the student table.
begin;
insert into takes (id, course_id, sec_id, semester, year, grade)
	values('69730', '313', '1', 'Fall', 2010, 'A');
update student
	set tot_cred = tot_cred+3
	where id = '69730';
commit;


													--INTEGRITY CONSTRAINTS-------REVIEW.
													
--Guard against accidental damage to the database by ensuring that authorized changes to the database
--...do not result in a loss of data consistency.
	--An instructors name cannot be null.
	--No two instructors can have the same ID
	--Every department name in the course relation must have a matching department name in the dept relation.
	--Budget of the department must be greater than $0.00

					--NOT NULL CONSTRAINTS
	--Prohibits the insertion of a nuull value for the attribute - a domain constraint
	
					--UNIQUE CONSTRAINTS
	--unique(A1,A2,...An)
		--The attributes for a candidate key.
		--Candidate keys are permitted to be null unleass they have explictly been declared to be not null.
		
					--THE CHECK CLAUSE
	--check(P0 clause specifies a predicate P that must be satisfied by every tuple in a relation.
	--EX: Ensure that semester is one of fall, winter, spring or summer
		--create table ...
		--.....
		--check(semester in ('Fall','Winter','Spring','Summer'));
		
					--REFERENTIAL INTEGRITY
	--Ensures that a value that appears in one relation for a given set of attributes also appears for..
	--..a certain set of attributes in another relation.
	--Foregin keys can be specified as part of the SQL create table statement
		--foreign key(dept_name) references department
		--The foreign key references the primary key attributes of the referenced table.

					--CASCADING ACTION IN REFERENTUAL INTEGRITY
	--When a referential-integrity constrain is viloated, the normal procedure is to reject..
	--..the action that caused the violation.
	--An alternative is to cascade
	
	create table course(
	(...
	dept_name varchar(20),
	foreign key(dept_name) references department
		on delete cascade
		on update cascade,
		..)
		--If there is a chain of foreign key dependencies across multiple relations, a deletion
		--..or update at one end of the chain can propagate across the entire chain.
	--Instead of cascade we can use:
		set null,
		set default,

					--ASSIGNING NAMES TO CONSTRAINTS
	--When creating an instructor table:
	create table instructor
		(ID varchar(5),
		name varchar(20) not null,
		dept_name varchar(20),
		salary numeric(8,2), constraint minsalary check (salary>29000), --constraint for the min salary
		primary key(ID),
		foreign key(dept_name) references departmment(dept_name)
				on delete set null
		);

	--To drop the constraint:
		alter table instructor drop constraint minsalary;

					--INTEGRITY CONSTRAINT VIOLATION DURING TRANSACTION
--Consider:
	create table person(
		ID char(10),
		name char(40),
		mother char(10),
		father char(10),
		primary key ID,
		foreign key father references person,
		foreign key mother references person
	);
	--How to insert a tuple without causing a constraint violation?
		--insert father and mother of a person before inserting person?
		--OR DEFER constraint checking:
	create table person(
		ID char(10),
		name char(40),
		mother char(10),
		father char(10),
		primary key ID,
		foreign key father references person deferrable,
		foreign key mother references person deferrable
	);
	begin;
	--defer the constraints if needed.
	set constraints all deferred;
	--insert the son without immediate parent's records
	insert into person(ID,name) values ('3', 'Son');
	--Now insert the father
	insert into person(ID,name) values ('1', 'Father');
	--Now the mother:
	insert into person(ID,name) values ('2', 'Mother');

	update person set father = '1', mother = '2' where ID = '3';
	commit;

					--COMPLEX CHECK CONDITIONS
--The predicate in the check clause can be an arbitrary predicate that can include a subquery.
	check(time_slot_id in (select time_slot_id from time_slot));
	--The time_slot_id in each tuple of the section relation is actually the identifier of a time slot in the 
	--..time_slot relation.
		--This condition has to be check when a tuple is inserted or modified in section, AND ALSO when the..
		--..relation time_slot changes.

					--ASSERTIONS
--A predicate expressing a condition that we wish the DB always has to satisfy.
--What can be expressed using assertions?:
	--For each tuple in the student relation, the value of the attribute tot_cred must equal the sum..
	--.. of credits of courses that the student has completed.
	--An instructor cannot teach in two different classrooms in a semester in the same time slot.
--ASSERTION FORM:
	create assertion<assertion-name> check(<predicate>);
	

													--SQL DATA TYPES AND SCHEMAS
													
					--BUILT IN DATA TYPES
--date, time, timestamp, interval.

					--TYPE CONVERSION AND FORMATTING FUNCTIONS
--Use the form cast (e as t) to convert an expression e to the type t.
	select cast(ID as numeric(5)) as inst_id
	from instructor
	order by inst_id;

					--LARGE OBJECT TYPES
--Large objects are stored as large object data types
	--blob: binary large object: a collection of binary data to be interpreted outside of the DB
	--clob: character large object

					--USER DEFINED TYPES
--create type construct in sql creates a user defined type.
	create type dollars as (amount numeric(12,2));

	create table department
	(dept_name varchar(20),
	building varchar(15),
	budget dollars);

					--DOMAINS
--Create domain construct creates a user defined domain type
	create domain person_name as char(20) not null;
	--Types and domains are similar, domains can have constraints such as not null on them.
	--can be restricted to contain only a specified set of values by using the in clause.
		create domain degree_level varchar(10)
			constraint degree_level_test
				check(value in('Bachelors', 'Masters', 'Doctorate'));

					--CREATE TABLE EXTENSIONS
--Applications often require the creation of tables that have the same schema as an existing table.
	create table tempInstructor(like instructor);
	create table tempInstructor(like instructor including all);
		--Foreign key constraints are not included in the copy.

	create table t1 as
		(select *
		from instructor
		where dept_name = 'Biology')
	with data;
	--By default the names and data types of the columns are inferred from the query result.
	--If the with data clause is omitted, the table is created but not populated with data.


													--INDEX CREATION--

--Many queries reference only a small proportion of the records in a table.
--Inefficient for the system to read every record to find a record with a certain value
--An index on an attribute of a relation is a data structore that allows the DB system to find those..
--..tuples in the relation that have a specified value for that attribute effiviently, without scanning through..
--..all the tuples of the relation.
--Create Index:
	create index<name> on <relation-name>(attribute);
--EX:
	create index studentID_index on student(ID);
	create index deptIndex on instructor(dept_name);
	--Drop
	drop index deptIndex;
	--Find all indexes
	select * from pg_indexes;

							
													--AUTHORIZATION--

--May assign a user several forms of auths.
	--read
	--insert: insertion of new data, no modification of existing data.
	--update: modification but not deletion
	--delete

--Forms of auths to modify the db schema
	--index: allows creation and deletion of indicies.
	--resources: allows creation of new relations
	--alteration: allows addition of attrubutes in a relation
	--drop: allows deletion

					--Authorization Specification
--grant statement is used to confer auth.
	grant<privelege list>
	on<relation or view>
	to<user list>

--<user list> is:
	--a user id
	--public
	-- a role

--EX: 
	grant select 
	on department
	to Amit, Satoshi  

--Revoking
	revoke<privelege list>
	on <relation or view>
	from <user list>
--EX:
	revoke select
	on department
	from Amit, Satoshi;

--CREATE USER:
	create user Amit with password 'Amit';
	create user Satoshi with password 'Satoshi';

--ROLES
	--A way to distinguish among user and their priveleges
--Create Role:
	create role instructor;
	grant instructor to Amit;

--Grant priveleges to role
	grant select on takes to instructor;

--Grant role to a role
	create role teachingAssistant;
	grant teachingAssistant to instructor;

					--AUTHORIZATION ON VIEWS
create role geo_staff;
					
create view geoInstructor as
(select*
from instructor
where dept_name = 'Geology');

grant select on geoInstructor to geo_staff;

select * from geoInstructor;







													





