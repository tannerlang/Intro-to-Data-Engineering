---Functions and Procedures
CREATE OR REPLACE FUNCTION dept_count(dept_name_input VARCHAR(20))
RETURNS INTEGER AS $$
DECLARE
    d_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO d_count
    FROM instructor
    WHERE instructor.dept_name = dept_name_input;
    RETURN d_count;
END;
$$ LANGUAGE plpgsql;


SELECT dept_count('Comp. Sci.');



select dept_name, budget
from department
where dept_count('Comp. Sci.') > 2


select dept_name, budget
from department
where dept_count(dept_name) > 2

---Table functions with department name and count
CREATE OR REPLACE FUNCTION dept_instructor_count(dept_name_input VARCHAR(20))
RETURNS TABLE(department_name VARCHAR(20), instructor_count BIGINT) AS $$
BEGIN
    RETURN QUERY
    SELECT dept_name, COUNT(*)::BIGINT
    FROM instructor
    WHERE dept_name = dept_name_input
    GROUP BY dept_name;
END;
$$ LANGUAGE plpgsql;


SELECT * FROM dept_instructor_count('Comp. Sci.');


---SQL Procedure
CREATE OR REPLACE PROCEDURE dept_count_proc(IN dept_name_input VARCHAR(20), 
											OUT d_count INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(*) INTO d_count
    FROM instructor
    WHERE dept_name = dept_name_input;
END;
$$;

--Calling above procedure
DO $$
DECLARE
    d_count INTEGER;
BEGIN
    CALL dept_count_proc('Comp. Sci.', d_count);
    RAISE NOTICE 'The count of instructors in the Comp. Sci. department is %', d_count;
END $$;



--- Register student function
-- Registers a student after ensuring classroom capacity is not exceeded
-- Returns 0 on success, and -1 if capacity is exceeded.
CREATE OR REPLACE FUNCTION registerStudent(
    s_id VARCHAR(5),
    s_courseid VARCHAR(8),
    s_secid VARCHAR(8),
    s_semester VARCHAR(6),
    s_year NUMERIC(4,0),
    OUT result INTEGER,
    OUT errorMsg VARCHAR(100)
) AS $$
DECLARE
    currEnrol INTEGER;
    class_capacity INTEGER;
BEGIN
    -- Initialize errorMsg to an empty string
    errorMsg := '';

    -- Get current enrollment count
    SELECT COUNT(*) INTO currEnrol
    FROM takes
    WHERE course_id = s_courseid AND sec_id = s_secid
    AND semester = s_semester AND year = s_year;

    -- Get classroom capacity limit
    SELECT capacity INTO class_capacity
    FROM classroom 
    JOIN section ON classroom.building = section.building 
                AND classroom.room_number = section.room_number
    WHERE course_id = s_courseid AND sec_id = s_secid
    AND semester = s_semester AND year = s_year;

    -- Check if current enrollment is less than classroom capacity
    IF currEnrol < class_capacity THEN
        -- Insert new enrollment record
        INSERT INTO takes (ID, course_id, sec_id, semester, year, grade)
        VALUES (s_id, s_courseid, s_secid, s_semester, s_year, NULL);

        -- Set success result
        result := 0;
    ELSE
        -- Set error message if capacity is exceeded
        errorMsg := 'Enrollment limit reached for course ' || s_courseid || 
                    ' section ' || s_secid;

        -- Set failure result
        result := -1;
    END IF;
END;
$$ LANGUAGE plpgsql;



-- Execute the function and retrieve the result
--success
DO $$
DECLARE
    v_result INTEGER;
    v_errorMsg VARCHAR(100);
BEGIN
    SELECT * INTO v_result, v_errorMsg
    FROM registerStudent('12345', 'FIN-201', '1', 'Spring', 2018);

    RAISE NOTICE 'Result: %, ErrorMsg: %', v_result, v_errorMsg;
END $$;
--error
DO $$
DECLARE
    v_result INTEGER;
    v_errorMsg VARCHAR(100);
BEGIN
    SELECT * INTO v_result, v_errorMsg
    FROM registerStudent('12345', 'HIS-351', '1', 'Spring', 2017);

    RAISE NOTICE 'Result: %, ErrorMsg: %', v_result, v_errorMsg;
END $$;

--- Trigger

CREATE OR REPLACE FUNCTION update_credits() RETURNS TRIGGER AS $$
BEGIN
  -- Check if the grade has changed from 'F' or null to a passing grade
  IF (NEW.grade <> 'F' AND NEW.grade IS NOT NULL) AND
     (OLD.grade = 'F' OR OLD.grade IS NULL) THEN
    -- Update the total credits in the student table
    UPDATE student
    SET tot_cred = tot_cred + 
      (SELECT credits FROM course WHERE course.course_id = NEW.course_id)
    WHERE student.id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER credits_earned
AFTER UPDATE OF grade ON takes
FOR EACH ROW
EXECUTE FUNCTION update_credits();

--- Disable Trigger
ALTER TABLE takes DISABLE TRIGGER credits_earned;

--- Enable Trigger
ALTER TABLE takes ENABLE TRIGGER credits_earned;

--- Drop Trigger
DROP TRIGGER credits_earned ON takes;

---Recursion
delete from prereq;
INSERT INTO prereq (course_id, prereq_id) VALUES
('BIO-301', 'BIO-101'),
('BIO-399', 'BIO-101'),
('CS-190', 'CS-101'),
('CS-315', 'CS-190'),
('CS-319', 'CS-101'),
('CS-319', 'CS-315'),
('CS-347', 'CS-319');


WITH RECURSIVE rec_prereq(course_id, prereq_id) AS (
    SELECT course_id, prereq_id
    FROM prereq
    UNION
    SELECT rp.course_id, p.prereq_id
    FROM rec_prereq rp
    JOIN prereq p ON rp.prereq_id = p.course_id
)
SELECT *
FROM rec_prereq
where course_id = 'CS-347';

--or
WITH RECURSIVE rec_prereq(course_id, prereq_id) AS (
    SELECT course_id, prereq_id
    FROM prereq
	where course_id = 'CS-347'
    UNION
    SELECT rp.course_id, p.prereq_id
    FROM rec_prereq rp
    JOIN prereq p ON rp.prereq_id = p.course_id
)
SELECT *
FROM rec_prereq;

---Ranking
CREATE VIEW student_grades AS
SELECT ID, ROUND(AVG(numeric_grade),2) AS GPA
FROM (
    SELECT ID,
           CASE grade
               WHEN 'A' THEN 4.0
               WHEN 'A-' THEN 3.7
               WHEN 'B+' THEN 3.3
               WHEN 'B' THEN 3.0
               WHEN 'B-' THEN 2.7
               WHEN 'C+' THEN 2.3
               WHEN 'C' THEN 2.0
               WHEN 'C-' THEN 1.7
               WHEN 'D+' THEN 1.3
               WHEN 'D' THEN 1.0
               WHEN 'F' THEN 0.0
               ELSE NULL -- If a grade doesn't translate to a GPA, treat it as NULL
           END AS numeric_grade
    FROM takes
) AS subquery
WHERE numeric_grade IS NOT NULL -- Exclude entries that couldn't be converted to a GPA
GROUP BY ID;


select * 
from student_grades 
order by gpa;


select ID, rank() over (order by GPA desc) as s_rank
from student_grades;


select ID, rank() over (order by GPA desc) as s_rank
from student_grades
order by s_rank;

select *
from (select ID, rank() over (order by GPA desc) as s_rank
	from student_grades)
where s_rank <= 5;

select ID, dense_rank() over (order by GPA desc nulls last) as s_rank
from student_grades;

select ID, rank() over (order by GPA desc nulls last) as s_rank
from student_grades;


select ID, (1 + (select count(*)
				 from student_grades B
				 where B.GPA > A.GPA)) as s_rank
from student_grades A
order by s_rank;


CREATE VIEW dept_grades AS
SELECT sg.ID, s.dept_name, sg.GPA
FROM student_grades sg
JOIN student s ON sg.ID = s.ID;

select ID, dept_name,
rank () over (partition by dept_name order by GPA desc) as dept_rank
from dept_grades
order by dept_name, dept_rank;

select ID, ntile(4) over (order by GPA desc) as quartile
from student_grades;

---Windowing
create view tot_credits as
	SELECT takes.year, sum(course.credits) AS num_credits
	FROM (takes JOIN course USING (course_id))
	GROUP BY takes.year;

--3 year window
select year, round(avg(num_credits)
				over (order by year rows 3 preceding), 2)
				as avg_total_credits
from tot_credits;
				   
--all prior years window
select year, round(avg(num_credits)
				over (order by year rows unbounded preceding), 2)
				as avg_total_credits
from tot_credits;

--Preceding and following year window
select year, round(avg(num_credits)
				over (order by year rows between 3 preceding and 2 following), 2)
				as avg_total_credits
from tot_credits;


--view function by department
CREATE VIEW tot_credits_dept AS
SELECT  course.dept_name, takes.year, SUM(course.credits) AS num_credits
FROM takes
JOIN course ON takes.course_id = course.course_id
GROUP BY course.dept_name, takes.year;

--partitioning by department
select dept_name, year, round(avg(num_credits)
			over (partition by dept_name
			order by year rows between 3 preceding and current row),2)
			as avg_total_credits
from tot_credits_dept;





--Pivot -- Filter
SELECT item_name,
       clothes_size,
       SUM(quantity) FILTER (WHERE color = 'dark') AS dark,
       SUM(quantity) FILTER (WHERE color = 'pastel') AS pastel,
       SUM(quantity) FILTER (WHERE color = 'white') AS white
FROM sales
GROUP BY item_name, clothes_size
ORDER BY item_name, clothes_size;



---Rollup and cube
select item_name, sum(quantity) as quantity
from sales
group by item_name;


select item_name, color, sum(quantity) as quantity
from sales
group by item_name, color ;


select item_name, color, sum(quantity)
from sales
group by rollup(item_name, color)
order by color, item_name;


select item_name, color, clothes_size, sum(quantity)
from sales
group by cube(item_name, color, clothes_size);


select item_name, color, clothes_size, sum(quantity)
from sales
group by rollup(item_name), rollup(color, clothes_size);


select item_name, color, clothes_size, sum(quantity)
from sales
group by grouping sets ((color, clothes_size), (clothes_size, item_name));


select (case when grouping(item_name) = 1 then 'all'
else item_name end) as item_name,
(case when grouping(color) = 1 then 'all'
else color end) as color,
sum(quantity) as quantity
from sales
group by rollup(item_name, color);

