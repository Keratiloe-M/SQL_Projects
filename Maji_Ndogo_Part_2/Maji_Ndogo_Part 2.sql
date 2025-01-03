/* Project Part 2: Clustering data to unveil majindogo water crisis*/

use md_water_services;
set sql_safe_updates=0;

-- Part 1- Cleaning our data
-- Creating an email for employees

SELECT * FROM md_water_services.employee;

-- Replace space with a comma (in name)
SELECT
Replace (employee_name, ' ','.')
From employee;

-- Make it lower case
SELECT
Lower(Replace (employee_name, ' ','.'))
From employee;

-- sticth to create email
SELECT
CONCAT(
LOWER(REPLACE(employee_name, ' ', '.')), '@ndogowater.gov') AS new_email
FROM employee;

-- now we now it works, lets update the table
UPDATE employee
SET email = CONCAT(LOWER(REPLACE(employee_name, ' ', '.')),
'@ndogowater.gov');

-- Fixing phone number
-- Check current length
select length(phone_number) as lenth_phonenumber
FROM employee;

-- remove space at the end of number
SELECT
length(rtrim(phone_number))
FROM employee;

-- now we see it works, lets update the number
select lenght(phone_number) as lenth_phonenumber;
Update employee
set phone_number= rtrim(phone_number);

/* PART 2- HONORING THE WORKERS*/

-- Let's look into the employee table
SELECT * FROM md_water_services.employee;

-- count how many employess live in each town
select town_name,
count(town_name) as employee_count
FROM md_water_services.employee
Group by town_name;
-- We see that majority of employees live in the rural areas

-- Search for top 3 surveyors with the most visits
Select * FROM visits;

Select assigned_employee_id,
count(visit_count) as total_visits
FROM md_water_services.visits
Group by assigned_employee_id
Order by total_visits desc
limit 3;
-- It was employee ID 1, 30 and 34

-- Check name, email address and phone number of above top 3 surveyors
SELECT assigned_employee_id, employee_name, phone_number, email
FROM employee
where assigned_employee_id
IN (1, 30, 34);
/* Bello Azibo +99643864786 bello.azibo@ndogowater.gov
Pili Zola +99822478933 pili.zola@ndogowater.gov
Rudo Imani +99046972648 rudo.imani@ndogowater.gov*/

/* PART THREE-ANALYSING LOCATIONS*/

SELECT * FROM md_water_services.location;

-- Calculate number of record per town
Select town_name,
count(town_name) AS records_per_town
FROM md_water_services.location
group by town_name
order by records_per_town desc;

-- Calculate number of record per province
Select province_name,
count(province_name) AS records_per_province
FROM md_water_services.location
group by province_name
order by records_per_province desc;

-- Show town name, province name and records per town
Select town_name,province_name,
count(*) as records_per_town
FROM md_water_services.location
group by town_name,province_name
order by province_name asc, records_per_town desc;

-- Calculate number of records in each location type
Select location_type,
count(location_type) AS num_sources
FROM md_water_services.location
group by location_type
order by num_sources;

-- Rural% and urban % 
SELECT 23740 / (15910 + 23740) * 100 as rural_percentage;
SELECT 15910 / (15910 + 23740) * 100 as urban_percentage;

/* PART 4- Diving into the sources*/
/* Tap in home, tap in home broken, well, shared tap, river*/
SELECT * FROM md_water_services.water_source;
SELECT distinct type_of_water_source FROM md_water_services.water_source;

-- 1. How many people did we survey in total?
select sum(number_of_people_served) as total_surveyed
FROM md_water_services.water_source;

-- 2. How many Tap in home, tap in home broken, well, shared tap and rivers are there?
Select type_of_water_source,count(type_of_water_source) as number_of_sources
from md_water_services.water_source
group by type_of_water_source
order by number_of_sources;

-- 3. How many people share particular types of water sources on average?
Select type_of_water_source, 
round(avg(number_of_people_served)) as avg_people_per_source
from md_water_services.water_source
group by type_of_water_source
order by avg_people_per_source;

-- 4. How many people are getting water from each type of source?
Select type_of_water_source, 
sum(number_of_people_served) as sum_people_per_source
from md_water_services.water_source
group by type_of_water_source
order by sum_people_per_source desc;

-- 5. Percentage people per source
-- We have a total of 27 628 140 citizens in total
Select type_of_water_source, 
round((sum(number_of_people_served)/27628140)*100,0) as perc_people_per_source
from md_water_services.water_source
group by type_of_water_source
order by perc_people_per_source desc;

/* PART 5-START OF A SOLUTION*/

-- Rank the sources by number of people served,excluding tap in home
Select type_of_water_source , sum(number_of_people_served) as sum_people_per_source,
rank() over (order by sum(number_of_people_served) desc) as ranked_population
from md_water_services.water_source
where type_of_water_source in ('river','tap_in_home_broken','well','shared_tap')
group by type_of_water_source
order by sum_people_per_source desc;

-- Rank source iD by number of people served
SELECT * FROM md_water_services.water_source;

-- Add number of people served per source iD
Select source_id, 
sum(number_of_people_served) as sum_people_per_id
from md_water_services.water_source
group by source_id
order by sum_people_per_id desc;

-- Rank each iD per sum of people served using Rank()
Select source_id, type_of_water_source,number_of_people_served,
rank() over (partition by type_of_water_source 
order by number_of_people_served desc) as priority_rank
from md_water_services.water_source
where type_of_water_source <>'tap in home';

-- Rank each iD per sum of people served using Dense Rank() option2
select distinct source_id, type_of_water_source, number_of_people_served,
rank() over (order by number_of_people_served desc ) as priority_rank
from md_water_services.water_source
where type_of_water_source != 'tap_in_home';

-- Rank each iD per sum of people served using Dense Rank()
Select source_id, type_of_water_source,number_of_people_served,
dense_rank() over (partition by type_of_water_source 
order by number_of_people_served desc) as priority_rank
from md_water_services.water_source
where type_of_water_source <>'tap in home';

-- Rank each iD per sum of people served using Dense Rank()
Select source_id, type_of_water_source,number_of_people_served,
row_number() over (partition by type_of_water_source 
order by number_of_people_served desc) as priority_rank
from md_water_services.water_source
where type_of_water_source <>'tap in home';



/* PART 6-Analysing queues*/
describe md_water_services.visits;
SELECT * FROM md_water_services.visits;

-- 1. How long did the survey take?
-- First get first date and last date on record
select min(time_of_record) as min_date,
max(time_of_record) as max_date
FROM md_water_services.visits;

-- Now get the difference between the first and last date
select datediff(max(time_of_record),min(time_of_record)) as days_taken
FROM md_water_services.visits;

-- 2. What is the average total queue time for water?
select avg(nullif(time_in_queue,0)) as avg_time_in_queue
FROM md_water_services.visits;

-- 3. So let's look at the queue times aggregated across the different days of the week
-- First lets look at day names
Select time_of_record,
dayname(time_of_record) as day_of_week
from md_water_services.visits;

-- Now lets calculate average waiting time for each day
Select dayname(time_of_record) as day_of_week,
round(avg(nullif(time_in_queue,0)),0) as avg_queue_time
from  md_water_services.visits
group by day_of_week;

-- 4.1. look at what time during the day people collect water and average time
Select hour(time_of_record) as hour_of_day,
round(avg(nullif(time_in_queue,0)),0) as avg_queue_time
from  md_water_services.visits
group by hour_of_day
order by hour_of_day;

-- 4.2 Lets edit the hour to look better 6:00 instead of 6
Select TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
round(avg(nullif(time_in_queue,0)),0) as avg_queue_time
from  md_water_services.visits
group by hour_of_day
order by hour_of_day;

-- Lets view average time in queue for each hour of the day
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
DAYNAME(time_of_record),
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END AS Sunday
FROM  md_water_services.visits
visits
WHERE
time_in_queue != 0; -- this exludes other sources with 0 queue times.

-- 5.2 Lets add other days
SELECT
TIME_FORMAT(TIME(time_of_record), '%H:00') AS hour_of_day,
-- Sunday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Sunday' THEN time_in_queue
ELSE NULL
END
),0) AS Sunday,

-- Monday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Monday' THEN time_in_queue
ELSE NULL
END
),0) AS Monday,

-- Tuesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Tuesday' THEN time_in_queue
ELSE NULL
END
),0) AS Tuesday,

-- Wednesday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Wednesday' THEN time_in_queue
ELSE NULL
END
),0) AS Wednesday,

-- Thursday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Thursday' THEN time_in_queue
ELSE NULL
END
),0) AS Thursday,

-- Friday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Friday' THEN time_in_queue
ELSE NULL
END
),0) AS Friday,

-- Saturday
ROUND(AVG(
CASE
WHEN DAYNAME(time_of_record) = 'Saturday' THEN time_in_queue
ELSE NULL
END
),0) AS Saturday

FROM
md_water_services.visits
WHERE
time_in_queue != 0 -- this excludes other sources with 0 queue times
GROUP BY
hour_of_day
ORDER BY
hour_of_day;
