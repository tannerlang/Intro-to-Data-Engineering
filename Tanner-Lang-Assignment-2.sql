------Question 1--------------
SELECT i.ID, i.name
FROM instructor i
LEFT JOIN teaches t ON i.ID = t.ID
WHERE t.ID IS NULL;

------Question 2--------------
CREATE VIEW students_without_advisor AS
SELECT s.ID, s.name
FROM student s
LEFT JOIN advisor a ON s.ID = a.s_ID
WHERE a.s_ID IS NULL;

--Select all records from the view:
SELECT * FROM students_without_advisor;

------Question 3----------------
SELECT i.name AS instructor_name, 
       c.title AS course_title, 
       s.room_number
FROM instructor i
JOIN teaches t ON i.ID = t.ID
JOIN section s ON t.course_id = s.course_id 
              AND t.sec_id = s.sec_id 
              AND t.semester = s.semester 
              AND t.year = s.year
JOIN course c ON t.course_id = c.course_id
WHERE t.semester = 'Spring' AND t.year = 2018;

---------Question 4----------------
CREATE VIEW instructor_advising_summary AS
SELECT 
    i.name AS instructor_name, 
    i.dept_name AS department_name, 
    COUNT(a.s_ID) AS total_students_advised
FROM instructor i
LEFT JOIN advisor a ON i.ID = a.i_ID
GROUP BY i.ID, i.name, i.dept_name;

------Selects all records in the view:
SELECT * FROM instructor_advising_summary;


----------Question 5---------
ROLLBACK; --before i run script again if I do.

BEGIN;


DELETE FROM teaches
WHERE ID = '10101' 
AND course_id = 'CS-315'
AND semester = 'Spring' 
AND year = 2018;

INSERT INTO teaches (ID, course_id, sec_id, semester, year)
SELECT '10101', 'CS-319', sec_id, 'Spring', 2018
FROM section
WHERE course_id = 'CS-319' 
AND semester = 'Spring' 
AND year = 2018
AND NOT EXISTS (
    SELECT 1 FROM teaches 
    WHERE ID = '10101' 
    AND course_id = 'CS-319' 
    AND semester = 'Spring' 
    AND year = 2018
)
LIMIT 1;

COMMIT;

-----------Question 6----------------
-----Part A:
DROP TABLE IF EXISTS instructor CASCADE;

CREATE TABLE instructor (
    ID         VARCHAR(5) PRIMARY KEY,
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    salary     NUMERIC(8,2) CONSTRAINT salary_check CHECK (salary > 35000),
    FOREIGN KEY (dept_name) REFERENCES department (dept_name) ON DELETE SET NULL
);

------Part B:
ALTER TABLE instructor DROP CONSTRAINT salary_check;

---------view the table-------
SELECT * FROM instructor;


---------Question 7--------------------
-----Part A:
CREATE TABLE upper_level_students (
    ID         VARCHAR(5) PRIMARY KEY,
    name       VARCHAR(20) NOT NULL,
    dept_name  VARCHAR(20),
    tot_cred   NUMERIC(3,0) CHECK (tot_cred >= 60),
    FOREIGN KEY (dept_name) REFERENCES department (dept_name) ON DELETE SET NULL
);

------Part B:
CREATE INDEX idx_upper_level_students_id
ON upper_level_students (ID);

CREATE INDEX idx_upper_level_students_dept
ON upper_level_students (dept_name);

------View the table
SELECT * FROM upper_level_students;


