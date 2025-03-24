--------------------------------------------------CHAPTER 5: ADVANCED SQL----------------------------------------------------

												
												--FUNCTIONS AND PROCEDURES--
/*
- Functions and procedures allow business logic to be stored in the DB and executed from SQL statements.
- Can be defined either by the procedural component of SQL or by an external programming language such as Java, C, or C++.
- The syntax we present here is defined by the SQL standard.
	-Most DB implement nonstandard versions of this syntax.
*/

			-- 1.DECLARING SQL FUNCTIONS IN POSTGRES
--Given the name of a department, returns the count number of instructors in that department.
	create or replace function dept_count(dept_name_input varchar(20))
	returns integer as $$
	declare
		d_count integer;
	begin
		select count(*) into d_count
		from instructor
		where instructor.dept_name = dept_name_input;
		return d_count;
	end;
	$$ language plpgsql;

	select dept_count('Comp. Sci.');

--The function dept_count can be used to find the department names and budget of all departments with more than 1 instructor.
	select dept_name, budget
	from department
	where dept_count(dept_name) > 2;	--Where department has more than 2 instructors


			-- 2.TABLE FUNCTIONS
--Can return tables as results
	create or replace function dept_instructor_count(dept_name_input varchar(20))
	returns table(department_name varchar(20), instructor_count BIGINT) as $$	--returns table, with attributes you define.
	begin
		return query
		select dept_name, count(*)::BIGINT
		from instructor
		where dept_name = dept_name_input
		group by dept_name;
	end;
	$$ language plpgsql;

	select*
	from dept_instructor_count('Comp. Sci.');

			-- 3.SQL PROCEDURES IN POSTGRES
--The dept_count function can also be written as a procedure: !!'in' & 'out' are params with vals set in the procedure
	create or replace procedure dept_count_proc(in dept_name_input varchar(20), out d_count integer) 
	language plpgsql
	as $$
	begin
		select count(*) into d_count
		from instructor
		where dept_name = dept_name_input;
	end;
	$$;
	
	--Procedures can be invoked either from an SQL procedure or from embedded SQL, using the call statement.
	do $$
	declare
		d_count integer;
	begin
		call dept_count_proc('Comp. Sci.', d_count);
		raise notice 'The count of instructors in the Comp. Sci. department is %',
		d_count;
	end $$;
/*
- Procedures and functions can be invoke also from dynamic SQL.
- SQL permits more than one procedure of the same name, so long as the number of arguments of the procedures with the same
  name is different.
- The name, along with the number of arguments, is used to identify the procedure.
*/


			-- 4.LANGUAGE CONSTRUCTS FOR PROCEDURES AND FUNCTIONS
/*
- SQL supports constructs that give it almost all the power of a general-purpose programming language.

- Compound statement: begin...end,
	- May contain multiple SQL statements between begin and end.
	- Local variables can be declared within a compound statement.
	
- While and repeate statements:
	- while boolean expression do
		sequence of statements;
	  end while

	- repeat
		sequence of statements;
	  until boolean expression
	  end repeat

- For loop
	- Permits iteration over all results of a query
	-EX:
*/
--For loop Example:
	declare n integer default 0;
	for r as
		select budget from department
		where dept_name = 'Music'
	do
		set n = n + r.budget
	end for;

			-- 5.LANGUAGE CONSTRUCTS - IF-THEN-ELSE
/*
- Conditional statements (if-then-else)
	if boolean expression
		then statement or compound statement
	elseif boolean expression
		then statement or compount statement
	else statement or compound statement
	end if
*/

			-- 6.EXTERNAL LANGUAGE ROUTINES
/*
- SQL allows us to define functions in a programming language such as java c#, c or C++.
	- Can be more efficient than functions defined in SQL, and computations that cannot be carried out in SQL\can be ex
	  executed by these functions.

- Declaring external language procedures and functions

	create procedure dept_count_proc(in dept_name varchar(20), out count integer)
	language C
	external name '/usr/avi/bin/dept_count_proc'

- Benefits of External language functions/procedures:
	- More efficient for many operations, and more excessive power.

- Drawbacks:
	- Code to implement may need to be loaded into the DB system and executed in the database system's address space.
		- Risk of accidental corruption of database structures.
		- Security risk, allowing users access to unauthorized data.
	- Alternatives give good security to the cost of worse performance
	- Direct execution in the database system's space is used when efficiency is more important than security.
*/

			-- 7.SECURITY WITH EXTERNAL LANGUAGE ROUTINES
/*
- To deal with security problems, we can:
	- Use 'sandbox' techniques
		- Use a safe language like java which cannot be used to access/damage other parts of the DB code.
	- Run external lang functions/procs in a separate process, with no access to the DB process' memory.
		- Parameters and results communicated via inter-process communication.

- Both have performance overheads
- Many DB systems support both above approaches as well as direct executing in DB system address space.
*/




												--TRIGGERS--
											   --REVIEW THIS--
/*
- A Trigger is a statement that is executed automatically by the system as a side effect of a modification to the DB.
- To design a trigger we must:
	 - Specify conditions to be executed/
	 - Specify the actions to be taken when the trigger executes.
*/

			-- 1.TRIGGERING EVENTS AND ACTIONS IN SQL
/*
- Triggering event can be insert, delete , or update
- Triggers on update can be restricted to specific attributes
	- EX: 'after update of takes on grade'
- Values of attributes before and after an update can be referenced.
	- 'referencing old row as'
	- 'referenceing new row as'
*/

			-- 2.TRIGGER TO MAINTAIN credits_earned VALUE
/*
- A trigger can be used to keep the total credit attribute value of student tuples up-to-date when the grade attribute is 
  updated for a tuple in the takes relation.
- The trigger is executed only when the grade attribute is updated from a value that is either null or 'F' to a grade that
  indicates the course is successfully completed
*/
	create or replace function update_credits() returns trigger as $$
	begin
	--check if grade has changed from 'F' or null to a passing grade.
		if(new.grade <> 'F' and new.grade is not null) and (old.grade = 'F' or old.grade is null) then
	--update the tot credits in the student table
		update student
		set tot_cred = tot_cred + (select credits from course where course.course_id = new.course_id)
		where student.id = new.id;
		end if;
		return new;
	end;
	$$ language plpgsql;

	create trigger credits_earned
	after update of grade on takes
	for each row
	execute function update_credits();


			-- 3.STATEMENT LEVEL TRIGGERS
/*
- Instead of executing a separate action for each affected row, a single action can be executed for all rows affected by
  a transition.
	- Use 'for each statement' instead of 'for each row'
	- Use referencing old table or referencing new table to refer to temp tables containing affected rows.
	- Can be more efficient when dealing with sql statements that update a large number of rows.
*/

			-- 4. WHEN NOT TO USE TRIGGERS
/*
- Triggers were used earlier for tasks like: 
	- Maintaining summary data
	- Replicating DBs by recording changes to special relations and having a separate process that applies the changes
	  over to a replica.

- Triggers are better ways of doing these now:
	- DBs today provide built in materialized view facilities to maintain summary data.
	- DBs provide built in support for replication
	
- Encapsulation facilities can be used instead of triggers in many cases:
	- Define methods to update fields.
	- Carry out actions as part of the update methods instead of through a trigger.

- Risk of unintended execution of triggers, for example when:
	- Loading data from a backup.
	- Replicating updates at a remote site.
	- Trigger execution can be disabled before these actions.

- Other risks with triggers:
	- Error leading to failure of critical transactions that set off the trigger.
	- The action of one trigger can set off another trigger. In the worst case, could leade to infinite triggering.
*/



												--RECURSIVE QUERIES--

/*
- Recursive views make it possible to write queries, such as transitive closure queries, that cannot be written without
  recursion or iteration.
*/

			-- 1.RECURSION IN SQL
/*
- In university schema, there is a cs course prerequisite.
- CS-347 - CS-319 - CS-315 - CS-190 - CS-101
- Find which courses are a prereq, wheter directly or indirectly for a specific course
*/

	with recursive rec_prereq(course_id,prereq_id) as(
		select course_id, prereq_id
		from prereq
		union
		select rp.course_id, p.prereq_id
		from rec_prereq rp
		join prereq p on rp.prereq_id = p.course_id
	)
	select*
	from rec_prereq;

/*
- Recursive query must be monotonic; its result on a view relation instance V1 must be a superset of its result on a view
  relation instance V2 if V1 is a superset of V2.

- Each recursive step can only add information; it cannot remove or modify what was added in previous step, which ensures
  that the recursive eventually completes and does not enter an infinite loop/

- Recursive queries can not use:
	- Aggregation on the recursive view.
	- Not exists on a subquery that uses the recursive view.
	- Set difference (exept) whose right-handed side uses the recursive view.
-Because they make the query non-monotonic.
*/


												--ADVANCED AGGREGATION FEATURES--
			-- 1.RANKING

-- Done in conjunction with an order by specification.
--Suppose we are given the relation student_grades(ID,GPA)

	create view student_grades as
	select ID, round(avg(numeric_grade),2) as GPA
	from(
		select ID,
		case grade
		when 'A' then 4.0
		when 'A-' then 3.7
		when 'B+' then 3.3
		when 'B' then 3.0
		when 'B-' then 2.7
		when 'C+' then 2.3
		when 'C' then 2.0
		when 'C-' then 1.7
		when 'D+' then 1.3 
		when 'D' then 1.0 
		when 'F' then 0.0
		else null --if grade doesnt translate, it is null
		end as numeric_grade
		from takes
	) as subquery
	where numeric_grade is not null
	group by id;

-- Find the rank of each student, sorted in order
	select id, rank() over (order by GPA desc) as s_rank
	from student_grades
	order by s_rank

-- Ranking may leave gaps, if 2 students have the same top gpa, obth have rank one and the next is 3
-- use dense_rank

	select id, dense_rank() over (order by GPA desc nulls last) as s_rank
	from student_grades
	order by s_rank

-- Ranking can be done within partition of data.
-- Find the rank of students within each department:

	create view dept_grades as
	select sg.id, s.dept_name, sg.gpa
	from student_grades sg
	join student s on sg.id = s.id;

	select id, dept_name,
	dense_rank() over (partition by dept_name order by gpa desc)
		as dept_rank
	from dept_grades
	order by dept_name, dept_rank;

/*
- For a given constant n, the ranking the function ntile(n) takes in each partition in the specified order, and
  divides them into n buckets with equal numbers of tuples:
*/
	select ID, ntile(4) over (order by GPA desc) as quartile
		from student_grades;



												--WINDOWING--
											   --REVIEW THIS--
/*
- Window queries compute an aggregate function over ranges of tuples.
- For each example, to compute an aggregate of a fixed range of time;
- The time range is called a window.
- Windows may overlap, in which case a tuple may contribute to more than one window.
- An example of the use of windowing is trend analysis.
	- Sales trend
	- Stock market Trend
- SQL provides a windowing feature
*/

select column1, column2, aggregate(function)
over
	(partition by column_name
	order by column_name
	rows between start_point and end_point)
from table;

--The view tot_credits: Giving the total number of credits taken by students in each year.
	create view tot_credits as
		select takes.year, sum(course.credits) as num_credits
		from (takes join course using(course_id))
		group by takes.year;

		--3 year window
		select year, round(avg(num_credits)over (order by year rows 3 preceding),2)
		as avg_total_credits
		from tot_credits;

		--All prior year window
		select year, round(avg(num_credits)over (order by year rows unbounded preceding), 2)
		as avg_total_credits
		from tot_credits;

		--Preceding and following year window
		select year, round(avg(num_credits)over (order by year rows between 3 preceding and 2 ), 2)
		as avg_total_credits
		from tot_credits;


--Credit data for each department view:
	create view tot_credits_department as
	select course.dept_name, takes.year, sum(course.credits) as num_credits
	from (takes join course using(course_id))
	group by course.dept_name, takes.year;


		--Preceding and following year window
		select dept_name, year, round(avg(num_credits) over(partition by dept_name
									order by year rows between 3 preceding and current row),2)
		as avg_total_credits
		from tot_credits_department;



												--PIVOTING--

/*
- Consider an application where a shop wants to find out what kinds of clothes are popular. Let us suppose that
  clothes are characterized by their item name, color, and size, and that we have a relation sales with the schema.
  	- sales: item name, color, clothes size, quantitiy

- Pivoting is also known as cross-tabulation or Pivot-Table
- Cross-tab(pivot table) is a table derived from a relation (R), where values for some attribute of relation R (A) become
  attribute names in the result; the attribute A is the pivot attribute.
*/

--Example
	select *
	from sales
	pivot(
		sum(quantity)
		for color in ('dark', 'pastel', 'white')
	);

--POSTGRES EX:
	select item_name, clothes_size,
		sum(quantity)filter(where color = 'dark') as dark,
		sum(quantity)filter(where color = 'pastel') as pastel,
		sum(quantity)filter(where color = 'white') as white
	from sales
	group by item_name, clothes_size
	order by item_name, clothes_size;




												--ROLLUP AND CUBE--
												 --REVIEW AGAIN--
/*
- Supports generalizations of the group by construct.
- Allows multiple group by queries to be run in a single query, with the result returned as a single relation.
- USed to create subtotals and grand totals within a result set.
*/
/*
			--ROLLUP

- Used when the analysis follows a hierarchical ordering.
- Rollup creates a hierarchy of subtotals that move from the most detailed level up to a grand total.
	- It adds one level of aggregation at a time from left to right as specified in the GROUP BY clause.
- The order of columns in the rollup is significant. The first column is the most detailed level, and the last is the 
  highes level, usually ending with the grand total.


  			--CUBE
- Cube is used when you need a comprehensive multi dimensional analysis. It generates all possible combinations of 
  subtotals and a grand total.



 --Both provide valuable data summarization capabilities, but CUBE can produce a much large result set due to the number
   of combinations that it generates.
*/

--Find the number of items sold in each item name with a simple group by query:
	select item_name, sum(quantity) as quantity
	from sales
	group by item_name;

--Find the number of items sold in each color, and each size
	select item_name, color, sum(quantity) as quantity
	from sales
	group by item_name, color;

--ROLLUP:
	select item_name, color, sum(quantity)
	from sales
	group by rollup(item_name, color);

--CUBE
	--Generates a larger number of groupings consisting of all subsets of the attributes listed in the cube construct
	select item_name, color, clothes_size, sum(quantity)
	from sales
	group by cube(item_name, color, clothes_size);

--Multiple rollups and cubes can be used in a single group by clause
	select item_name, color, clothes_size, sum(quantity)
	from sales
	group by rollup(item_name), rollup(color, clothes_size);

--Neither rollup or cube gives complete control on the grouping generated.
	--Can using grouping sets construct to specify that we only want groupings
	select item_name, color, clothes_size, sum(quantity)
	from sales
	group by grouping sets((clothes_size,item_name),(color, clothes_size));

--To distinguish nulls generated by rollup and cube
	select(case when grouping(item_name) = 1 then 'all'
			else item_name end) as item_name,
		  (case when grouping(color) = 1 then 'all'
		  	else color end) as color,
	sum(quantity) as quantity
	from sales
	group by rollup(item_name, color);










	