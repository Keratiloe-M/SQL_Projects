/* Project 1 Madi_Ndogo*/

-- This is to use the Maji ndogo database.
Use md_water_services; 

-- Section 1- Get to know our data
/* There is a table named data dictionary that shows all the table names, column names in each table, the description of each column,
 the data type of each colum and an indication of any relationship each column has with another table. 
 Let's look at the data dictionary table.*/
 
 SELECT * FROM data_dictionary;
 
 -- We can also look only the names of each table
 
SHOW tables;

-- Let us look into a few tables

Select * FROM location ; -- Looking into location table

/* So we can see that this table has information on a specific location, with an address, the province and town the location is in,
 and if it's in a city (Urban) or not. We can't really see what location this is but we can see some sort of identifying number 
 of that location*/

Select * FROM visits -- Looking into visits table and limiting rows to 5
LIMIT 5;

/*Yeah, so this is a list of location_id, source_id, record_id, and a date and time, so it makes sense that someone (assigned_employee_id)
 visited some location (location_id) at some time (time_of_record ) and found a 'source' there (source_id).  Often the "_id" columns 
 are related to another table. In this case, the source_id in the visits table refers to source_id in the water_source table */

-- Section 2- Dive into the water source
-- Now we want to see only the unique water sources.

select distinct type_of_water_source FROM water_source; 

-- Let us describe these water sources

/* 1. River - People collect drinking water along a river. This is an open water source that millions of people use in Maji Ndogo. Water from
a river has a high risk of being contaminated with biological and other pollutants, so it is the worst source of water possible.*/

/* 2. Well - These sources draw water from underground sources, and are commonly shared by communities. Since these are closed water
sources, contamination is much less likely compared to a river. Unfortunately, due to the aging infrastructure and the corruption of 
officials in the past, many of our wells are not clean.*/

/* 3. Shared tap - This is a tap in a public area shared by communities.*/

/* 4. Tap in home - These are taps that are inside the homes of our citizens. On average about 6 people live together in Maji Ndogo, so
each of these taps serves about 6 people.*/

/* 5. Broken tap in home - These are taps that have been installed in a citizen’s home, but the infrastructure connected to that tap is not
functional. This can be due to burst pipes, broken pumps or water treatment plants that are not working.*/

-- Refer to the guide for more information regarding these water sources

-- Section 3 - Unpack the visits to water sources

-- Firstly, lets look at visits where people waited in the queue for more than 8 hours
SELECT * FROM visits
WHERE time_in_queue >=500; 

-- Which water sources have people waiting for more than 8 hours? Let's check using the top 5 source_ids with the most waiting time
SELECT * FROM water_source
where source_id
IN ('AmRu14612224','HaRu19538224','AkRu05704224','HaRu20126224','SoRu35388224');

-- We can see that the water source that has people waiting for hours to collect water is shared taps

-- Now lets look at visits where waiting time is zero.
SELECT * FROM visits
WHERE time_in_queue =0; 

-- I now want these water sources with no waiting time
SELECT * FROM water_source
where source_id
IN ('KiRu28935224','AkLu01628224','AmDa12214224','KiRu28520224','HaZa21742224');

-- It looks like the sources tap in home and well have a less waiting time.

-- Section 4-  Assess the quality of water sources:

/* Home taps were rated 10 (10 being clean and 1 being terrible), and the surveyors only visited home taps once. 
Lets check if the data reflected this correctly.*/

select * from water_quality
where subjective_quality_score = 10 
AND visit_count=2; 

/* I get 218 results instead of zero, so it looks like the data has some errors*/

-- Section 5- Investigate pollution issues

/* If a well is clean the the biological units is zero, any well that had a unit greater than 0.01 is contaminated. Let's check if the data
captured this correctly*/

SELECT * FROM well_pollution
WHERE results='Clean'
and biological > 0.01
limit 50;

/* It looks like there are results that are marked clean even if biological is greater than 0.01. 
Lets Fix this*/
SELECT * FROM well_pollution
WHERE description  Like 'Clean_%';

-- Lets create a copy of the well pollution table before we update it

CREATE TABLE
md_water_services.well_pollution_copy
AS (
SELECT
*
FROM
md_water_services.well_pollution
);

-- Now we fix the problem

UPDATE
well_pollution_copy
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution_copy
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution_copy
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

-- Now lets check if the above fix worked
SELECT * FROM well_pollution_copy
WHERE 
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);

-- Now we see that it works, lets delete the copy table
DROP TABLE md_water_services.well_pollution_copy;

-- Now lets change the original table
SET SQL_SAFE_UPDATES=0;

UPDATE
well_pollution
SET
description = 'Bacteria: E. coli'
WHERE
description = 'Clean Bacteria: E. coli';

UPDATE
well_pollution
SET
description = 'Bacteria: Giardia Lamblia'
WHERE
description = 'Clean Bacteria: Giardia Lamblia';

UPDATE
well_pollution
SET
results = 'Contaminated: Biological'
WHERE
biological > 0.01 AND results = 'Clean';

SELECT * FROM well_pollution
WHERE 
description LIKE "Clean_%"
OR (results = "Clean" AND biological > 0.01);








