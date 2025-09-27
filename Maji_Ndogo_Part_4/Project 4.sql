use md_water_services;

/* PART ONE - JOINING PIECES TOGETHER*/

-- 07:58 Join location and visits

-- First lets view the two tables
SELECT * FROM md_water_services.location; 
SELECT * FROM visits;

-- Now lets join the two tables
Select location.province_name,
        location.town_name,
        visits.visit_count,
        visits.location_id
From visits
Join location
On visits.location_id=location.location_id;

-- Now add water source table

-- Let me see how water source table looks like
SELECT * FROM md_water_services.water_source;

-- Now let me join it with visits and location
Select location.province_name,
        location.town_name,
        visits.visit_count,
        visits.location_id,
        water_source.type_of_water_source,
        water_source.number_of_people_served
From visits
Join location
On visits.location_id=location.location_id
Join water_source
On water_source.source_id=visits.source_id;

-- 08:21
/* Note that there are rows where visit_count > 1. 
These were the sites our surveyors collected additional information for, 
but they happened at the same source/location. 
For example, add this to your query: WHERE visits.location_id = 'AkHa00103'*/

Select location.province_name,
        location.town_name,
        visits.visit_count,
        visits.location_id,
        water_source.type_of_water_source,
        water_source.number_of_people_served
From visits
Join location
On visits.location_id=location.location_id
Join water_source
On water_source.source_id=visits.source_id
where visits.location_id = 'AkHa00103';


-- 08:31 Lets remove these duplicates

Select location.province_name,
        location.town_name,
        visits.visit_count,
        visits.location_id,
        water_source.type_of_water_source,
        water_source.number_of_people_served
From visits
Join location
On visits.location_id=location.location_id
Join water_source
On water_source.source_id=visits.source_id
where visit_count=1;

/* 08;37 Ok, now that we verified that the table is joined correctly, 
we can remove the location_id and visit_count columns.*/

-- 08:38 Add the location_type column from location and time_in_queue from visits
Select location.province_name,
        location.town_name,
		water_source.type_of_water_source,
		location.location_type,
		water_source.number_of_people_served,
        visits.time_in_queue
From visits
Join location
On visits.location_id=location.location_id
Join water_source
On water_source.source_id=visits.source_id
where visit_count=1;

-- 8:50 Now add well pollution using left join

-- Lets look at the well pollution table 1st.
Select * from well_pollution;

SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM visits
LEFT JOIN well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN location
ON location.location_id = visits.location_id
INNER JOIN water_source
ON water_source.source_id = visits.source_id
WHERE visits.visit_count = 1;

-- 09:51 Now lets create a view of the above query
CREATE VIEW combined_analysis_table AS
SELECT
water_source.type_of_water_source,
location.town_name,
location.province_name,
location.location_type,
water_source.number_of_people_served,
visits.time_in_queue,
well_pollution.results
FROM visits
LEFT JOIN well_pollution
ON well_pollution.source_id = visits.source_id
INNER JOIN location
ON location.location_id = visits.location_id
INNER JOIN water_source
ON water_source.source_id = visits.source_id
WHERE visits.visit_count = 1;

-- -----------------------------------------------------------------------

/* PART TWO - THE LAST ANALYSIS*/

-- 09:14 we want to break down our data into provinces or towns and source types

-- calculate the population of each province
SELECT province_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name
;

-- Now lets calculate the population of each province per water type
SELECT province_name, SUM(number_of_people_served) AS river_total_ppl_serv
FROM combined_analysis_table
where type_of_water_source ='river'
GROUP BY province_name
;

-- Lets see what happens if we multiply the sum by 100
SELECT province_name, SUM(number_of_people_served)*100 AS river_total_ppl_serv
FROM combined_analysis_table
where type_of_water_source ='river'
GROUP BY province_name
;

-- Lets get a %
SELECT province_name, SUM(number_of_people_served)*100 AS river_total_ppl_serv
FROM combined_analysis_table
where type_of_water_source ='river'
GROUP BY province_name
;


-- Create a CTE that calculates the population of each province
WITH province_totals AS (
SELECT province_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name
)
SELECT
ct.province_name,
-- These case statements create columns for each type of source.
-- The results are aggregated and percentages are calculated
ROUND((SUM(CASE
            WHEN type_of_water_source = 'river' 
			THEN number_of_people_served 
            ELSE 0 
            END) * 100.0 / pt.total_ppl_serv), 0) 
            AS river,
           
ROUND((SUM(CASE 
           WHEN type_of_water_source = 'shared_tap'
           THEN number_of_people_served 
           ELSE 0 
           END) * 100.0 / pt.total_ppl_serv), 0) 
           AS shared_tap,

ROUND((SUM(CASE
		WHEN type_of_water_source = 'tap_in_home'
        THEN number_of_people_served 
        ELSE 0 
        END) * 100.0 / pt.total_ppl_serv), 0) 
        AS tap_in_home,

ROUND((SUM(CASE 
		WHEN type_of_water_source = 'tap_in_home_broken'
        THEN number_of_people_served 
        ELSE 0 
        END) * 100.0 / pt.total_ppl_serv), 0) 
        AS tap_in_home_broken,

ROUND((SUM(CASE
           WHEN type_of_water_source = 'well'
           THEN number_of_people_served
           ELSE 0 
           END) * 100.0 / pt.total_ppl_serv), 0) 
           AS well

FROM combined_analysis_table ct
JOIN province_totals pt 
ON ct.province_name = pt.province_name
GROUP BY ct.province_name
ORDER BY ct.province_name;


-- Now lets group the number of people served by town name and province name
-- Since there are two Harare towns, we have to group by province_name and town_name

SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name;

-- Create a CTE
WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)

SELECT ct.province_name,
       ct.town_name,
       
ROUND((SUM(CASE 
           WHEN type_of_water_source = 'river'
		   THEN number_of_people_served 
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS river,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'shared_tap'
		   THEN number_of_people_served 
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'tap_in_home'
           THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS tap_in_home,

ROUND((SUM(CASE
		   WHEN type_of_water_source = 'tap_in_home_broken'
		   THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'well'
           THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS well

FROM combined_analysis_table ct
JOIN town_totals tt 
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name -- Since the town names are not unique, we have to join on a composite key
GROUP BY  ct.province_name, ct.town_name -- We group by province first, then by town.
ORDER BY ct.town_name;

-- 10:15 Lets create a temporary table to store the CTE

CREATE TEMPORARY TABLE town_aggregated_water_access 
WITH town_totals AS (
SELECT province_name, town_name, SUM(number_of_people_served) AS total_ppl_serv
FROM combined_analysis_table
GROUP BY province_name,town_name
)

SELECT ct.province_name,
       ct.town_name,
       
ROUND((SUM(CASE 
           WHEN type_of_water_source = 'river'
		   THEN number_of_people_served 
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS river,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'shared_tap'
		   THEN number_of_people_served 
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) AS shared_tap,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'tap_in_home'
           THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS tap_in_home,

ROUND((SUM(CASE
		   WHEN type_of_water_source = 'tap_in_home_broken'
		   THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) AS tap_in_home_broken,

ROUND((SUM(CASE 
           WHEN type_of_water_source = 'well'
           THEN number_of_people_served  
           ELSE 0 
           END) * 100.0 / tt.total_ppl_serv), 0) 
           AS well

FROM combined_analysis_table ct
JOIN town_totals tt 
ON ct.province_name = tt.province_name AND ct.town_name = tt.town_name -- Since the town names are not unique, we have to join on a composite key
GROUP BY  ct.province_name, ct.town_name -- We group by province first, then by town.
ORDER BY ct.town_name;

-- Lets view this table we created
select * from town_aggregated_water_access;

-- 10:20 Lets order by river DESC
select * from town_aggregated_water_access
order by river DESC;

-- 10:21 Lets look at town Amina in Amanzi
select * from town_aggregated_water_access
where province_name='Amanzi' and town_name='Amina';

-- 10:25 which town has the highest ratio of people who have taps, but have no running water?
SELECT province_name, town_name,
	   ROUND(tap_in_home_broken / (tap_in_home_broken + tap_in_home) * 100,0) AS Pct_broken_taps
FROM
town_aggregated_water_access
Order by Pct_broken_taps desc; -- To see which towns with highest ratio 1st

/* PART FOUR-PRACTICAL PLAN*/

-- Lets create a table named Project Progress
DROP Table Project_progress;

CREATE TABLE Project_progress (
Project_id SERIAL PRIMARY KEY, -- Unique key for sources in case we visit the same source more than once in the future.
source_id VARCHAR(20) NOT NULL REFERENCES water_source(source_id) ON DELETE CASCADE ON UPDATE CASCADE, -- Each of the sources we want to improve should exist,and should refer to the source table
Address VARCHAR(50),
Town VARCHAR(30),
Province VARCHAR(30),
Source_type VARCHAR(50),
Improvement VARCHAR(50), -- What the engineers should do at that place
results varchar(255),
Source_status VARCHAR(50) DEFAULT 'Backlog' CHECK (Source_status IN ('Backlog', 'In progress', 'Complete')),
-- We want to limit the type of information engineers can give us so we limit Source_status.
-- By DEFAULT all projects are in the "Backlog" which is like a TODO list.
-- CHECK() ensures only those three options will be accepted. This helps to maintain clean data
Date_of_completion DATE, -- Engineers will add this the day the source has been upgraded.
Comments TEXT -- Engineers can leave comments. We use a TEXT type that has no limit on char length
);

-- We want to put data into our table but 1st lets take a few steps

-- 11:04 Step 1 Lets join the location, visits, and well_pollution tables to the water_source table

SELECT
location.address,
location.town_name,
location.province_name,
water_source.source_id,
water_source.type_of_water_source,
well_pollution.results
FROM
water_source
LEFT JOIN
well_pollution ON water_source.source_id = well_pollution.source_id
INNER JOIN
visits ON water_source.source_id = visits.source_id
INNER JOIN
location ON location.location_id = visits.location_id;

-- let's filter the data to only contain sources we want to improve by thinking through the logic first.

-- safe updates
 
 SET sql_safe_updates = 0;
 
 --  project_progress_query
 
DROP TEMPORARY TABLE IF EXISTS project_progress_query;

CREATE TEMPORARY TABLE project_progress_query AS (
    SELECT
    
        water_source.source_id AS source_id,
        location.address AS address,
        location.town_name AS town,
        location.province_name AS province,
        water_source.type_of_water_source AS source_type,
        well_pollution.results AS results,
        CASE
            WHEN water_source.type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Chemical' THEN 'Install RO filter'
            WHEN water_source.type_of_water_source = 'well' AND well_pollution.results = 'Contaminated: Biological' THEN 'Install UV and RO filter'
            WHEN water_source.type_of_water_source = 'river' THEN 'Drill well'
            WHEN water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30 THEN CONCAT('Install ', FLOOR(visits.time_in_queue / 30), ' taps nearby')
            WHEN water_source.type_of_water_source = 'tap_in_home_broken' THEN 'Diagnose local infrastructure'
            ELSE NULL
        END AS Improvement
    FROM
        water_source
    LEFT JOIN
        well_pollution ON water_source.source_id = well_pollution.source_id
    INNER JOIN
        visits ON water_source.source_id = visits.source_id
    INNER JOIN
        location ON location.location_id = visits.location_id
    WHERE
        visits.visit_count = 1  
        AND (
            (water_source.type_of_water_source = 'well' AND well_pollution.results != 'Clean')  
            OR water_source.type_of_water_source IN ('tap_in_home_broken', 'river') 
            OR (water_source.type_of_water_source = 'shared_tap' AND visits.time_in_queue >= 30)
        )
);
        
SELECT *
FROM project_progress_query; 

INSERT INTO project_progress (source_id, address, town, province, source_type, Improvement, results)
SELECT
	source_id,
    address,
    town,
    province,
    source_type,
    Improvement,
    results
FROM
	project_progress_query;
    
    
SELECT
project_progress.Project_id, 
project_progress.Town, 
project_progress.Province, 
project_progress.Source_type, 
project_progress.Improvement,
Water_source.number_of_people_served,
RANK() OVER(PARTITION BY Province ORDER BY number_of_people_served)
FROM  project_progress 
JOIN water_source 
ON water_source.source_id = project_progress.source_id
WHERE Improvement = "Drill Well"
ORDER BY Province DESC, number_of_people_served
     
     

/*Project_id 
source_id 
Address 
Town 
Province 
Source_type 
Improvement 
Source_status 
Date_of_completion 
Comments*/