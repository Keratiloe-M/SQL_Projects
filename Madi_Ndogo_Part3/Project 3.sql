/* PART 3: WEAVING THE DATA THREADS*/


/* Integrating the Auditor's report
To make sure we have the same names, use this query to create the table first, then Import the CSV file:*/

use md_water_services; 

DROP TABLE IF EXISTS `auditor_report`;
CREATE TABLE `auditor_report` (
`location_id` VARCHAR(32),
`type_of_water_source` VARCHAR(64),
`true_water_source_score` int DEFAULT NULL,
`statements` VARCHAR(255)
);

SELECT * FROM md_water_services.auditor_report;

/*Lets join the auditors report table to the visits table*/

SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score,
visits.location_id AS visit_location,
visits.record_id
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id;

/*Now that we have the record_id for each location, our next step is to retrieve the corresponding scores from the water_quality table.
 We are particularly interested in the subjective_quality_score. To do this, we'll JOIN the visits table and the water_quality table,
 using the record_id as the connecting key.*/
 
 Select * FROM visits;
 Select * FROM water_quality;
 
 SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality
ON water_quality.record_id = visits.record_id;

/* Lets check whether the auditors score and surveyor score agreee*/

 SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality
ON water_quality.record_id = visits.record_id
where true_water_source_score=subjective_quality_score
AND visits.visit_count=1; -- This is because some location were visited multiple times

-- Lets look at the 102 records that have different scores

SELECT
auditor_report.location_id AS audit_location,
auditor_report.true_water_source_score AS auditor_score,
visits.record_id,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality
ON water_quality.record_id = visits.record_id
where true_water_source_score!=subjective_quality_score
AND visits.visit_count=1; -- This is because some location were visited multiple times

-- Join type of water source to auditors table
SELECT * FROM md_water_services.water_source;
SELECT * FROM md_water_services.auditor_report;

SELECT
visits.location_id,
auditor_report.type_of_water_source AS auditor_source,
water_source.type_of_water_source AS survey_source,
visits.record_id,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality
ON water_quality.record_id = visits.record_id
JOIN
water_source
ON water_source.source_id=visits.source_id
where true_water_source_score!=subjective_quality_score
AND visits.visit_count=1; 

/* PART TWO- LIKING UP RECORDS TO EMPLOYEES*/

-- Now lets look at the employees that made these mistakes
SELECT * FROM md_water_services.employee; -- lets look at employee table to match with visits
SELECT * FROM md_water_services.visits;

SELECT
visits.location_id,
visits.record_id,
employee.assigned_employee_id,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM
auditor_report
JOIN
visits
ON auditor_report.location_id = visits.location_id
JOIN
water_quality
ON water_quality.record_id = visits.record_id
JOIN
employee
ON employee.assigned_employee_id = visits.assigned_employee_id
where true_water_source_score!= subjective_quality_score
AND visits.visit_count=1; 

-- Now lets get the employees names
SELECT 
visits.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM auditor_report
JOIN visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
JOIN employee
ON employee.assigned_employee_id = visits.assigned_employee_id
where true_water_source_score!= subjective_quality_score
AND visits.visit_count=1; 

-- Create a CE of the above query
WITH Incorrect_records AS
(SELECT 
visits.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
water_quality.subjective_quality_score AS surveyor_score
FROM auditor_report
JOIN visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality
ON water_quality.record_id = visits.record_id
JOIN employee
ON employee.assigned_employee_id = visits.assigned_employee_id
where true_water_source_score!= subjective_quality_score
AND visits.visit_count=1)

Select employee_name,
count(employee_name)
from Incorrect_records
group by employee_name;

/* PART 3-GATHERING EVIDENCE*/
-- Let's find all of the employees who have an above-average number of mistakes

-- 1. We have to first calculate the number of times someone's name comes up using a create view

CREATE VIEW Incorrect_records AS (
SELECT
auditor_report.location_id,
visits.record_id,
employee.employee_name,
auditor_report.true_water_source_score AS auditor_score,
wq.subjective_quality_score AS surveyor_score,
auditor_report.statements AS statements
FROM auditor_report
JOIN visits
ON auditor_report.location_id = visits.location_id
JOIN water_quality AS wq
ON visits.record_id = wq.record_id
JOIN employee
ON employee.assigned_employee_id = visits.assigned_employee_id
WHERE
visits.visit_count =1
AND auditor_report.true_water_source_score != wq.subjective_quality_score);

-- Lets see if it worked
 SELECT * FROM Incorrect_records;
 
 /* Next, we convert the query error_count, we made earlier, into a CTE.*/
 
 WITH error_count AS ( -- This CTE calculates the number of mistakes each employee made
SELECT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY employee_name)

SELECT
AVG(number_of_mistakes) AS avg_error_count_per_empl
FROM
error_count;

/*To find the employees who made more mistakes than the average person, we need the employee's names, the number of mistakes each one
made, and filter the employees with an above-average number of mistakes.*/

 WITH error_count AS (
SELECT employee_name,
COUNT(employee_name) AS number_of_mistakes
FROM
Incorrect_records
GROUP BY employee_name)

SELECT
employee_name,
number_of_mistakes
FROM error_count
WHERE
 number_of_mistakes> (select AVG(number_of_mistakes) FROM error_count);
 
 -- Overall calcs
 -- This CTE calculates the number of mistakes each employee made
 use md_water_services;
 
 WITH error_count AS ( 
SELECT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name),

suspect_list AS (-- This CTE SELECTS the employees with above−average mistakes
SELECT employee_name, number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))

-- This query filters all of the records where the "corrupt" employees gathered data.
SELECT employee_name, location_id, statements
FROM Incorrect_records
WHERE employee_name in (SELECT employee_name FROM suspect_list);

-- Filter the records that refer to "cash".
use md_water_services;
 
 WITH error_count AS ( 
SELECT employee_name, COUNT(employee_name) AS number_of_mistakes
FROM Incorrect_records
GROUP BY employee_name),

suspect_list AS (
SELECT employee_name, number_of_mistakes
FROM error_count
WHERE number_of_mistakes > (SELECT AVG(number_of_mistakes) FROM error_count))


SELECT employee_name, location_id, statements
FROM Incorrect_records
WHERE employee_name in (SELECT employee_name FROM suspect_list)
and statements LIKE "%cash%";





