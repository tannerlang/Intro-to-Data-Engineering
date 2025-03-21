-------ASSIGNMENT 3------------TANNER LANG

--------------------------------------------  QUESTION 1  ----------------------------------------------
DROP FUNCTION IF EXISTS department_instructor_count;	--Drop function if it already exists, conflict handling

--DELIVERABLE: CREATING THE FUNCTION
CREATE FUNCTION department_instructor_count()
RETURNS TABLE(dept_name VARCHAR(20), instructor_count BIGINT, rank INT) AS
$$
BEGIN
    RETURN QUERY
	--retrieve dept names and total num of instructors in each dept.
    SELECT d.dept_name, 
           COUNT(i.ID) AS instructor_count,	--counts instructors
           CAST(DENSE_RANK() OVER (ORDER BY COUNT(i.ID) DESC) AS INT) AS rank	--sets rank based on the count
    FROM department d
    LEFT JOIN instructor i ON d.dept_name = i.dept_name	--ensures all depts are included.
    GROUP BY d.dept_name			--group by name
    ORDER BY instructor_count DESC; --descending order to rank on faculty size.
END;
$$ LANGUAGE plpgsql;

--DELIVERABLE: CALLING THE FUNCTION
SELECT * FROM department_instructor_count();


--------------------------------------------  QUESTION 2  ----------------------------------------------

----------DELIVERABLE: TABLE MODIFICATION--------------
ALTER TABLE student ADD COLUMN enrollment_status VARCHAR(10);

----------DELIVERABLE: VIEW CREATION---------------
CREATE VIEW student_course_count AS
SELECT t.ID AS student_id, t.semester, t.year, COUNT(*) AS course_count
FROM takes t
GROUP BY t.ID, t.semester, t.year;

----------DELIVERABLE: FUNCTION CREATION--------------
--create a function to update enrollment status
CREATE FUNCTION update_enrollment_status()
RETURNS TRIGGER AS
$$
BEGIN
    UPDATE student			----updates enrollment
    SET enrollment_status = 
        CASE 
			--If student is enrolled in 3 or more classes in a semester, set status to full time
            WHEN (SELECT course_count FROM student_course_count 
                  WHERE student_id = NEW.ID AND semester = NEW.semester AND year = NEW.year) >= 3 
                THEN 'Full-Time'
			--set status to part time if 1 to 2 classes are enrolled in a semester
            WHEN (SELECT course_count FROM student_course_count 
                  WHERE student_id = NEW.ID AND semester = NEW.semester AND year = NEW.year) IN (1, 2) 
                THEN 'Part-Time'
            ELSE 'Not Enrolled'
        END
    WHERE ID = NEW.ID;		--apply update to affected student only.
    
    RETURN NEW;				--for trigger 
END;
$$ LANGUAGE plpgsql;

---------DELIVERABLE: TRIGGER CREATION-----------
CREATE TRIGGER trigger_update_enrollment_status
AFTER INSERT OR UPDATE OR DELETE ON takes
FOR EACH ROW EXECUTE FUNCTION update_enrollment_status();

----------DELIVERABLE: TRIGGER TESTING---------
--insert the student into the db
INSERT INTO student (ID, name, dept_name, tot_cred) 
VALUES ('76653', 'Assignment 3 Student', 'Marketing', 0);

--Insert a new enrollment record for studentID 76653
INSERT INTO takes (ID, course_id, sec_id, semester, year) 
VALUES ('76653', '313', '1', 'Fall', 2010);

--verify enrollment
SELECT ID, enrollment_status FROM student WHERE ID = '76653';

--Insert Two More Courses
INSERT INTO takes (ID, course_id, sec_id, semester, year) 
VALUES 
    ('76653', '415', '1', 'Fall', 2010),
    ('76653', '476', '1', 'Fall', 2010);

--Verifying again...
SELECT ID, enrollment_status FROM student WHERE ID = '76653';



--------------------------------------------  QUESTION 3  ----------------------------------------------


-----------DELIVERABLE: CREATING A VIEW:
CREATE VIEW student_semester_gpa AS
SELECT 
    id AS student_id,  -- renaming id to student_id to make it more readable
    semester,
    year,
    AVG(
		---converting the letter grade to numeric, so i can compute the average.
        CASE 
            WHEN grade = 'A' THEN 4.0
            WHEN grade = 'A-' THEN 3.7
            WHEN grade = 'B+' THEN 3.3
            WHEN grade = 'B' THEN 3.0
            WHEN grade = 'B-' THEN 2.7
            WHEN grade = 'C+' THEN 2.3
            WHEN grade = 'C' THEN 2.0
            WHEN grade = 'C-' THEN 1.7
            WHEN grade = 'D+' THEN 1.3
            WHEN grade = 'D' THEN 1.0
            WHEN grade = 'F' THEN 0.0
            ELSE NULL  
        END
    ) AS gpa  
FROM takes
GROUP BY id, semester, year;	-- grouping so we get avg gpa per semester per student

-------------DELIVERABLE: QUERY TO DISPLAY:
--displays student_id, semester, year, gpa, and cumulative gpa.
SELECT 
    student_id, 
    semester, 
    year, 
    gpa,
        -- compute cumulative gpa using a running avg
    AVG(gpa) OVER (
        PARTITION BY student_id 	-- calculate per student
        ORDER BY year, 
            CASE WHEN semester = 'Spring' THEN 1 ELSE 2 END	-- making sure spring is first
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW		-- include all past semesters
    ) AS cumulative_gpa
FROM student_semester_gpa
ORDER BY student_id, year, 
    CASE WHEN semester = 'Spring' THEN 1 ELSE 2 END;	-- sort so it's always spring then fall



--------------------------------------------  QUESTION 4  ----------------------------------------------	

	
----------DELIVERABLE: ROLLUP REPORT GENERATION
-- generate a report showing total enrollments per department, per year, with subtotals and a grand total
SELECT 
    d.dept_name, 
    t.year, 
    COUNT(*) AS total_enrollments	-- counting total enrollments per department per year
FROM takes t
JOIN course c ON t.course_id = c.course_id -- linking takes table to course table to get department info
JOIN department d ON c.dept_name = d.dept_name
GROUP BY ROLLUP (d.dept_name, t.year)	-- rollup to get requirements
ORDER BY d.dept_name, t.year;



--------------------------------------------  QUESTION 5  ----------------------------------------------	


----------DELIVERABLE: PIVOT QUERY
-- pivoting enrollment data to show the number of courses taken per semester
select 
    t.id as student_id,  -- renaming id to student_id ]
    t.year,  -- year to track enrollments 
    count(case when t.semester = 'Spring' then 1 end) as spring,  	-- counting courses taken in spring per student per year
    count(case when t.semester = 'Fall' then 1 end) as fall  -- counting courses taken in fall per student per year
from takes t
group by t.id, t.year  -- grouping by student and year 
order by t.id, t.year;  -- ordering by student and year


























