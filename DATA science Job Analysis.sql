data_science_salaries 

SELECT* FROM jobs

/* As a market researcher, your job is to Investigate the job market for a company that analyzes workforce data. 
Your Task is to know how many people were employed IN different types of companies AS per their size IN 2021.*/

SELECT Company_size,count(Job_title) FROM jobs
WHERE work_year = 2021
group by company_size

/*Imagine you are a talent Acquisition specialist Working for an International recruitment agency. 
Your Task is to identify the top 3 job titles that command the highest average salary Among part-time Positions IN the year 2023. 
However, you are Only Interested IN Countries WHERE there are more than 50 employees, Ensuring a robust sample size for your analysis.
*/
Select job_title,AVG(salary_in_usd) as 'average' from jobs 
where company_size IN ('large','medium') AND employment_type ='part-time'
group by job_title
ORDER BY AVG(salary_in_usd) DESC
LIMIT 3

/*As a database analyst you have been assigned the task to Select Countries where average mid-level salary is higher than overall mid-level salary for the year 2023.*/

WITH mid_level_salaries AS (
  SELECT AVG(salary_in_usd) AS overall_mid_level_salary
  FROM jobs
  WHERE experience_level = 'Mid-level'
),
country_mid_level_salaries AS (
  SELECT company_location, AVG(salary_in_usd) AS avg_mid_level_salary
  FROM jobs
  WHERE work_year = 2023 AND experience_level = 'Mid-level'
  GROUP BY company_location
)
SELECT company_location,avg_mid_level_salary,overall_mid_level_salary
FROM country_mid_level_salaries, mid_level_salaries
WHERE avg_mid_level_salary > overall_mid_level_salary;

-- As a database analyst you have been assigned the task to Identify the company locations with the highest and lowest average salary for senior-level (SE) employees in 2023.--
with senior_level_salary as 
(
SELECT 
	company_location,
    AVG(salary_in_usd) as avg_salary,
    row_number() over (ORDER BY AVG(salary_in_usd) DESC) as row_num_desc,
    row_number() over (ORDER BY AVG(salary_in_usd)) as row_num_asc
FROM 
	jobs
WHERE 
	work_year = 2023 and experience_level = 'senior-level'
Group by
	company_location
)

SELECT CASE
	WHEN row_num_desc = 1 THEN 'highest salary location'
    WHEN row_num_asc =1 THEN 'lowest salary location'
END AS 
	location_type,
    company_location,
    avg_salary
FROM senior_level_salary
WHERE row_num_desc =1 or row_num_asc = 1;

/*You're a Financial analyst Working for a leading HR Consultancy, and your Task is to Assess the annual salary growth rate for various job titles. 
By Calculating the percentage Increase IN salary FROM previous year to this year, you aim to provide valuable Insights Into salary trends WITHIN different job roles. 
identify the previous year salary 
logic 
1 identify previous year salary > calc growth rate > filter rows where prev salary is not null  */

WITH prev_year_salaries AS
(
	SELECT 
		job_title,
		work_year,
		salary_in_usd,
		LAG(salary_in_usd) OVER (PARTITION BY job_title order by work_year) As prev_year_salary
	FROM jobs 
)

SELECT job_title,work_year,salary_in_usd,salary_growth_rate
FROM    
    (SELECT job_title, work_year, salary_in_usd,
    round((salary_in_usd - prev_year_salary) / prev_year_salary * 100,2) AS salary_growth_rate 
FROM prev_year_salaries
WHERE prev_year_salary is NOT NULL) as growth_rates 
ORDER BY job_title, work_year;
    
/*
You've been hired by a global HR Consultancy to identify Countries experiencing significant salary growth for entry-level roles. Your task is 
to list the top three Countries with the highest salary growth rate FROM 2020 to 2023, Considering Only companies with more than 50 employees, 
helping multinational Corporations identify Emerging talent markets.
1 country , salary growth, experience_level = entry level company size medium or lkarge work year 2020-2023*/

-- calc %change -- 
SELECT 
    country,
    (avg_salary_2023 - avg_salary_2020) / avg_salary_2020 * 100 AS salary_growth_rate
FROM
    (SELECT 
        country,
            SUM(CASE
                WHEN work_year = 2020 THEN average_salary
                ELSE 0
            END) AS avg_salary_2020,
            SUM(CASE
                WHEN work_year = 2023 THEN average_salary
                ELSE 0
            END) AS avg_salary_2023
    FROM
        (SELECT 
        employee_residence AS country,
            work_year,
            AVG(salary_in_usd) AS average_salary
    FROM
        jobs
    WHERE
        work_year IN (2020 , 2023)
            AND company_size IN ('medium' , 'large')
            AND experience_level = 'entry-level'
    GROUP BY employee_residence , work_year) AS subquery
    GROUP BY country) AS subquery
ORDER BY salary_growth_rate DESC
LIMIT 3;

/*Picture yourself as a data architect responsible for database management. Companies in US and AU(Australia) decided to create a hybrid model for employees 
they decided that employees earning salaries exceeding $90000 USD, will be given work from home. You now need to update the remote work ratio for eligible employees, 
ensuring efficient remote work management while implementing appropriate error handling mechanisms for invalid input parameters.*/

CREATE TABLE CAMP AS SELECT * FROM JOBS;
SET SQL_SAFE_UPDATES = 0;
UPDATE CAMP
SET WORK_MODELS = 'REMOTE' 
WHERE (COMPANY_LOCATION = 'Australia' OR COMPANY_LOCATION = 'United States') and SALARY_IN_USD > 90000;
select * from camp WHERE SALARY_IN_USD > 90000

/* In the year 2024, due to increased demand in the data industry, there was an increase in salaries of data field employees.
Entry Level-35% of the salary.
Mid junior – 30% of the salary.
Immediate senior level- 22% of the salary.
Expert level- 20% of the salary.
Director – 15% of the salary.You must update the salaries accordingly and update them back in the original database.*/

UPDATE camp 
SET 
    salary_in_usd = CASE
        WHEN experience_level = 'Mid-level' THEN salary_in_usd * 0.3
        WHEN experience_level = ' Senior-level' THEN salary_in_usd * 0.22
        WHEN experience_level = 'Entry-level' THEN salary_in_usd * 0.35
        WHEN experience_level = 'Executive-level' THEN salary_in_usd * 0.15
    END
WHERE
    work_year = 2024;

/*9. You are a researcher and you have been assigned the task to Find the year with the highest average salary for each job title.*/

-- Calculate the average salary for each job title in each year
with avg_salary_per_year as
(SELECT job_title, AVG(salary_in_usd) as avg_salary , work_year FROM jobs group by work_year,job_title)

SELECT work_year,job_title, avg_salary 
FROM 
(
SELECT 
	work_year,
	job_title, avg_salary, 
    RANK() over(partition by job_title ORDER by avg_salary DESC) as rank_by_salary 
from 
	avg_salary_per_year
) as ranked_salary
where rank_by_salary = 1

/*10. You have been hired by a market research agency where you been assigned the task to show the percentage of different employment type (full time, part time) in 
Different job roles, in the format where each row will be job title, each column will be type of employment type and  cell value  for that row and column will show 
the % value*/

    
/*10. You have been hired by a market research agency where you been assigned the task to show the percentage of different employment type (full time, part time) in 
Different job roles, in the format where each row will be job title, each column will be type of employment type and  cell value  for that row and column will show 
the % value*/

SELECT 
	JOB_TITLE, 
    ROUND(SUM(CASE WHEN EMPLOYMENT_TYPE = 'Full-time' THEN 1 ELSE 0 END)/COUNT(*) * 100,2) AS FT_PC,
    ROUND(SUM(CASE WHEN EMPLOYMENT_TYPE = 'Part-time' THEN 1 ELSE 0 END)/COUNT(*) * 100,2) AS PT_PC,
    ROUND(SUM(CASE WHEN EMPLOYMENT_TYPE = 'Contract' THEN 1 ELSE 0 END)/COUNT(*) * 100,2) AS CT_PC,
    ROUND(SUM(CASE WHEN EMPLOYMENT_TYPE = 'Freelance' THEN 1 ELSE 0 END)/COUNT(*) * 100,2) AS FT_PC
FROM JOBS
GROUP BY JOB_TITLE