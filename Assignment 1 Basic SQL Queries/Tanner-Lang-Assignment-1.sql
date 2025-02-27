/*2a*/
SELECT DISTINCT s.ID, s.name
FROM student s
JOIN takes t ON s.ID = t.ID
JOIN section sec ON t.course_id = sec.course_id AND t.sec_id = sec.sec_id AND t.semester = sec.semester AND t.year = sec.year
JOIN course c ON sec.course_id = c.course_id
WHERE c.dept_name = 'Finance';

/*2b*/
SELECT s.ID, s.name
FROM student s
WHERE NOT EXISTS 
(
    SELECT 1
    FROM takes t
    JOIN section sec ON t.course_id = sec.course_id AND t.sec_id = sec.sec_id AND t.semester = sec.semester AND t.year = sec.year
    WHERE t.ID = s.ID AND sec.year < 2006
);

/*2C*/
SELECT dept_name, MIN(salary) AS min_salary
FROM instructor
GROUP BY dept_name;


/*2d*/
WITH department_max_salary AS 
(
    SELECT dept_name, MAX(salary) AS max_salary
    FROM instructor
    GROUP BY dept_name
)
SELECT MIN(max_salary) AS lowest_max_salary
FROM department_max_salary;


/*-------------------------------------------------------------------------------*/
/*3a*/
INSERT INTO course (course_id,title,dept_name,credits)
VALUES ('CS-001', 'Weekly Seminar', 'Comp. Sci.', 1);

/*3b*/
INSERT INTO section (course_id, sec_id, semester, year, building, room_number, time_slot_id)
VALUES ('CS-001', '1', 'Fall', 2009, NULL, NULL, NULL);

/*3c*/
INSERT INTO takes (ID, course_id, sec_id, semester, year, grade)
SELECT s.ID, 'CS-001', '1', 'Fall', 2009, NULL
FROM student s
WHERE s.dept_name = 'Comp. Sci.';

/*3d*/
DELETE FROM takes
WHERE course_id IN 
(
    SELECT course_id
    FROM course
    WHERE LOWER(title) LIKE '%advanced%'
);

/*----------------------------------------------------------------------------------------*/
/*4*/
SELECT dept_name
FROM department
WHERE budget > 
(
    SELECT budget
    FROM department
    WHERE dept_name = 'History'
)
ORDER BY dept_name;

/*----------------------------------------------------------------------------------------*/
/*5*/
SELECT s.name, s.ID
FROM student s
JOIN advisor a ON s.ID = a.s_ID
JOIN instructor i ON a.i_ID = i.ID
WHERE s.dept_name = 'History' AND i.dept_name = 'Finance';

/*----------------------------------------------------------------------------------------*/
/*6*/
SELECT dept_name
FROM 
(
    SELECT dept_name, SUM(salary) AS value
    FROM instructor
    GROUP BY dept_name
) AS dept_total,
(
    SELECT AVG(value) AS value
    FROM 
	(
        SELECT SUM(salary) AS value
        FROM instructor
        GROUP BY dept_name
    ) AS dept_total_inner
) AS dept_total_avg
WHERE dept_total.value >= dept_total_avg.value;


/*----------------------------------------------------------------------------------------*/
/*7*/
CREATE TABLE member
	(
	member_id SERIAL PRIMARY KEY
	name VARCHAR (50) not null,
	email VARCHAR(50) unique not null
	phone VARCHAR (20)
	
	);

CREATE TABLE book
	(
	isbn VARCHAR(20) PRIMARY KEY
	title VARCHAR(255) not null,
	author VARCHAR(100) not null,
	publication_year INT CHECK (publication_year > 0)
	);

CREATE TABLE loan 
	(
	loan_id SERIAL PRIMARY KEY,
	member_id INT not null,
	isbn VARCHAR(20) not null,
	loan_date DATE not null,
	return_date DATE,
	)











