use it_salaries;

select *
from `it salary survey eu  2020`;

CREATE TABLE `staging` (
  `Timestamp` text,
  `Age` int DEFAULT NULL,
  `Gender` text,
  `City` text,
  `Position` text,
  `Total years of experience` int DEFAULT NULL,
  `Years of experience in Germany` int DEFAULT NULL,
  `seniority` text,
  `pr_lang` text,
  `2nd prg_lang` text,
  `Yearly brutto salary in EUR` int DEFAULT NULL,
  `Yearly bonus + stocks in EUR` text,
  `Brutto_salary_one_year_ago` text,
  `Annual bonus+stocks` text,
  `Number of vacation days` int DEFAULT NULL,
  `Employment status` text,
  `Ð¡ontract duration` text,
  `Main language at work` text,
  `Company size` text,
  `Company type` text,
  `Job_loss_COVID` text,
  `Kurzarbeit_hours_week` text,
  `Wfh_extra_support_2020EUR` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into staging
select *
from `it salary survey eu  2020` 
;

select *
from staging;

SELECT 
    COUNT(*) AS Total,
    SUM(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS Missing_Age,
    SUM(CASE WHEN Gender IS NULL THEN 1 ELSE 0 END) AS Missing_Gender,
    SUM(CASE WHEN Position IS NULL THEN 1 ELSE 0 END) AS Missing_Position
FROM staging;


update staging
set Position = 'Leader'
where Position is null or trim(Position) = '';

select distinct Position
from staging;

select position
from staging
where position = 'Leader';

update staging
set 
	pr_lang = case
		when Position like ("%Designer%") and (pr_lang is null or trim(pr_lang) = '') then 'Not Applicable'
        when Position not like ("%Designer%") and (pr_lang is null or trim(pr_lang) = '') then 'Unknown'
        else pr_lang
	end,
    `2nd prg_lang` = case
		when Position like ("%Designer%") and (`2nd prg_lang` is null or trim(`2nd prg_lang`) = '') then 'Not Applicable'
        when Position not like ("%Designer%") and (`2nd prg_lang` is null or trim(`2nd prg_lang`) = '') then 'Unknown'
        else `2nd prg_lang`
	end;
        

select *
from staging;



UPDATE staging 
SET 
    `Annual bonus+stocks` = NULL
WHERE `Annual bonus+stocks` = 0;

UPDATE staging 
SET 
    `Yearly bonus + stocks in EUR` = NULL
WHERE `Yearly bonus + stocks in EUR` = 0;


SELECT *
FROM staging
WHERE `Annual bonus+stocks` IS NULL
   OR TRIM(`Annual bonus+stocks`) = '';

SELECT *
FROM staging
WHERE `Yearly bonus + stocks in EUR` IS NULL
   OR TRIM(`Yearly bonus + stocks in EUR`) = '';


UPDATE staging
SET 
    `Annual bonus+stocks` = CASE
        WHEN `Annual bonus+stocks` IS NULL OR TRIM(`Annual bonus+stocks`) = '' THEN
            ROUND(IFNULL(`Yearly bonus + stocks in EUR`, 0) * 0.85, 2)
        ELSE round(cast(`Annual bonus+stocks` as decimal(15,2)), 2)
    END,

    `Yearly bonus + stocks in EUR` = CASE
        WHEN `Yearly bonus + stocks in EUR` IS NULL OR TRIM(`Yearly bonus + stocks in EUR`) = '' THEN
            ROUND(IFNULL(`Annual bonus+stocks`, 0) / 0.85, 2)
        ELSE 
			round(cast(ifnull(`Yearly bonus + stocks in EUR`,0) as decimal(15,2)),2)
    END
WHERE 
    (`Annual bonus+stocks` IS NULL OR TRIM(`Annual bonus+stocks`) = '') 
    OR 
    (`Yearly bonus + stocks in EUR` IS NULL OR TRIM(`Yearly bonus + stocks in EUR`) = '');

update staging
set `Yearly bonus + stocks in EUR`=
	case
		when `Yearly bonus + stocks in EUR` !=0 and `Yearly bonus + stocks in EUR` != round(`Yearly bonus + stocks in EUR`)
        then round(`Yearly bonus + stocks in EUR`)
        else `Yearly bonus + stocks in EUR`
	end;
    
-- in order to remove extra values after the 0
    
alter table staging
modify `Yearly bonus + stocks in EUR` int;
alter table staging
modify `Annual bonus+stocks` int;

-- there are some equal salaries in both column/changing them

UPDATE staging
SET `Yearly bonus + stocks in EUR` = `Annual bonus+stocks` / 0.85
WHERE `Yearly bonus + stocks in EUR` = `Annual bonus+stocks` and `Yearly bonus + stocks in EUR` !=(`Annual bonus+stocks` / 0.85);

select *
from staging;


-- looking for is there incorrect salaries
SELECT `Annual bonus+stocks`, `Yearly bonus + stocks in EUR`
FROM staging
WHERE `Yearly bonus + stocks in EUR` <> (`Annual bonus+stocks` / 0.85);
-- correcting

UPDATE staging
SET `Yearly bonus + stocks in EUR` = `Annual bonus+stocks` / 0.85
WHERE `Yearly bonus + stocks in EUR` <> (`Annual bonus+stocks` / 0.85);

alter table staging
change column `Annual bonus+stocks` `Annual bonus+stocks GBP` int;

select *
from staging;

UPDATE staging
SET `Brutto_salary_one_year_ago` = NULL  -- or you can use `0` instead of `NULL`
WHERE TRIM(`Brutto_salary_one_year_ago`) = '';


alter table staging
modify column `Brutto_salary_one_year_ago` int;
	
update staging
set
	`Brutto_salary_one_year_ago` = case
		when `Brutto_salary_one_year_ago` is null or trim(`Brutto_salary_one_year_ago`) = ''
		then `Yearly brutto salary in EUR`
		else `Brutto_salary_one_year_ago`
	end
where `Brutto_salary_one_year_ago` is null or trim(`Brutto_salary_one_year_ago`) = '';

SELECT *
FROM staging;

-- filling avg hours to kurzarbeit hours
-- SET @avg_hours = (SELECT AVG(kurzarbeit_hours_week) FROM staging WHERE kurzarbeit_hours_week IS NOT NULL);

-- UPDATE staging
-- SET kurzarbeit_hours_week = @avg_hours
-- WHERE kurzarbeit_hours_week IS NULL OR TRIM(kurzarbeit_hours_week) = '';

-- filling by prediction

-- UPDATE staging t1
-- SET t1.kurzarbeit_hours_week = (
--     SELECT AVG(t2.kurzarbeit_hours_week)
--     FROM staging t2
--     WHERE t2.position = t1.position AND t2.kurzarbeit_hours_week IS NOT NULL
-- )
-- WHERE t1.kurzarbeit_hours_week IS NULL OR TRIM(t1.kurzarbeit_hours_week) = '';

-- filling 0 instead of missing values from kurzarbeit hours

-- filling with 'unknown'
UPDATE staging
SET kurzarbeit_hours_week = 'Unknown'
WHERE kurzarbeit_hours_week IS NULL OR TRIM(kurzarbeit_hours_week) = '';

select *
from staging;

UPDATE staging
SET Wfh_extra_support_2020EUR = 0
WHERE Wfh_extra_support_2020EUR IS NULL OR TRIM(Wfh_extra_support_2020EUR) = '';

UPDATE staging
SET Job_loss_COVID = 'Unknown'
WHERE Job_loss_COVID IS NULL OR TRIM(Job_loss_COVID) = '';

-- the highest percentage of pr_lang
SELECT 
    pr_lang, 
    COUNT(*) AS count,
    (COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staging)) AS percentage
FROM staging
GROUP BY pr_lang
ORDER BY percentage DESC
;
-- Percentage of employees affected by job loss
SELECT 
    Job_loss_COVID, 
    COUNT(*) * 100.0 / (SELECT COUNT(*) FROM staging) AS Percentage
FROM staging
GROUP BY Job_loss_COVID;
-- Support during work-from-home
SELECT 
    Wfh_extra_support_2020EUR, 
    COUNT(*) AS Count
FROM staging
WHERE Wfh_extra_support_2020EUR IS NOT NULL
GROUP BY Wfh_extra_support_2020EUR
ORDER BY COUNT(*) DESC;

-- Correlate years of experience with salary
SELECT 
    `Total years of experience`, 
    `Yearly brutto salary in EUR`
FROM staging
WHERE `Total years of experience` IS NOT NULL
ORDER BY CAST(`Total years of experience` AS UNSIGNED);

-- Average salary by gender
SELECT 
    Gender, 
    AVG(`Yearly brutto salary in EUR`) AS Avg_Salary, 
    COUNT(*) AS Count
FROM staging
GROUP BY Gender
ORDER BY Avg_Salary DESC
LIMIT 0, 1000;

-- Top roles and their average salaries
SELECT 
    Position, 
    COUNT(*) AS Role_Count, 
    AVG(`Yearly brutto salary in EUR`) AS Avg_Salary
FROM staging
GROUP BY Position
ORDER BY Role_Count DESC, Avg_Salary DESC;


-- Salary vs. company size
SELECT 
    `Company size`, 
    AVG(`Yearly brutto salary in EUR`) AS Avg_Salary,
    COUNT(*) AS Count
FROM staging
WHERE `Company size` IS NOT NULL
GROUP BY `Company size`
ORDER BY Avg_Salary DESC;

-- Analyze the change in salary over one year
SELECT 
    AVG(`Yearly brutto salary in EUR`) AS Current_Avg_Salary,
    AVG(`Brutto_salary_one_year_ago`) AS Past_Avg_Salary,
    AVG(`Yearly brutto salary in EUR`) - AVG(Brutto_Salary_One_Year_Ago) AS Salary_Growth
FROM staging
WHERE `Brutto_salary_one_year_ago` IS NOT NULL;

select *
from staging;