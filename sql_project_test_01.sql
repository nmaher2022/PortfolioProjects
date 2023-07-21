/*
Data Exploration project
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
Step 1: Load the data into Microsoft SQL from Excel files.
Step 2: Selecting the data for an initial overview 
Step 3: Analysis of infected cases, deaths compared with population
Step 4: Join the two tables, then use a window function to show the rolling total of vaccinations
Step 5: Create  common table expression for rolling total of vaccinations
Step 6: Create temporary table for rolling total of vaccinations
Step 7: Create view  for rolling total of vaccinations
*/

/*Step 1: Load the data into Microsoft SQL from Excel files.*/
/*Creating a database for the project called project_test*/
 USE MASTER;
 GO
	 
 IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'project_test')
BEGIN
  CREATE DATABASE project_test;
END;
GO

sp_configure 'Show Advanced Options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO

/* The commands below can also be set manually by going to -> Server Objects->Linked Servers->Providers->Microsoft.ACE.OLEDB.12.0->Properties*/
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1;
GO
EXEC sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1;
GO

The Excel worksheets are imported into SQL, while running SSMS as administrator*/
USE project_test;
SELECT * INTO CovidVaccinations
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0','Excel 12.0;Database=C:\Users\User\Documents\Covid_Vaccinations4.xlsx', [Sheet1$]);

/*Another way to import the files is to add a linked server with the file path to the Excel file*/
USE project_test;
SELECT * INTO CovidDeaths
FROM EXCELDATA...[Sheet1$];


/*Step 2: Selecting the data for an initial overview showing the first 10 rows
The command LIMIT does not work in Microsoft SQL,
instead an ORDER BY command required, along with an offset and then fetch the number of rows.
LIMIT 10 works for mySQL(although not in a subquery), PostgreSQL, Oracle. 
*/

SELECT * FROM project_test.dbo.CovidDeaths ORDER BY 3,4 
OFFSET 0 ROWS
FETCH FIRST 10 ROWS ONLY;

SELECT * FROM project_test.dbo.CovidVaccinations ORDER BY 3,4 
OFFSET 0 ROWS
FETCH FIRST 10 ROWS ONLY;

/* The date columns is renamed as date_column so they is no confusion with keyword date*/ 
EXEC sp_RENAME 'CovidDeaths.date','date_column','COLUMN'
GO
EXEC sp_RENAME 'CovidVaccinations.date','date_column','COLUMN'
GO

SELECT * FROM project_test.dbo.CovidDeaths ORDER BY 3,4 
OFFSET 0 ROWS
FETCH FIRST 10 ROWS ONLY;

/*Converting column of the number of new deaths which was a nvarchar type into an integer in order to do calculations with it later on*/
ALTER TABLE project_test.dbo.CovidDeaths ALTER COLUMN new_deaths INT;

/*Selecting specific columns now */
SELECT location,date_column,total_cases,new_cases,total_deaths,population
FROM project_test..CovidDeaths ORDER BY location,date_column;

/*Step 3:  Analysis of infected cases, deaths compared with population*/

/*Showing individual continents*/
SELECT DISTINCT continent
FROM project_test..CovidDeaths;

/*Percentage of deaths from cases, this shows the likelihood of dying if covid is contracted for Ireland */
SELECT location,date_column, total_cases,total_deaths, 
	ROUND((total_deaths/total_cases)*100.0,2) AS death_percentage
FROM project_test..CovidDeaths 
WHERE location LIKE 'Ireland'
ORDER BY location,date_column;

/*Percentage of deaths from cases, this shows likelihood of dying if covid is contracted for places with state in the name*/
SELECT location,date_column, total_cases,total_deaths,
		ROUND((total_deaths/total_cases)*100.0,2) AS death_percentage
FROM project_test..CovidDeaths 
WHERE location LIKE '%state%'
ORDER BY  location,date_column;

--Shows the percentage of the population with Covid for Ireland on each date
SELECT location,date_column, population,total_cases,
	ROUND((total_cases/population)*100,2) AS percentage_population_with_covid
FROM project_test..CovidDeaths 
WHERE location LIKE 'Ireland'
ORDER BY location,date_column;


/*Looking at the countries with the highest infection rate compared to population in descending order 
Group By only works here with the name of the column rather than the number in Microsoft SQL */
SELECT location,population,
	 MAX(total_cases) AS max_cases, 
	 ROUND(MAX((total_cases/population))*100.0,2) AS percentage_population_with_covid
FROM project_test..CovidDeaths 
GROUP BY location, population
ORDER BY percentage_population_with_covid DESC;

/*Finding continents and countries with highest death rates
total_deaths datatype is nvarchar so needs to be cast as an integer if the column has not been converted already*/
SELECT continent,location,
	MAX(CAST(total_deaths AS INT)) AS max_deaths
FROM project_test..CovidDeaths 
--WHERE Location LIKE 'Ireland'  // for ireland or a given country 
--Where continent is  null  // groups by continent 
--WHERE LOCATION NOT LIKE continent // gives just countries and not continents
GROUP BY continent,location
ORDER BY location DESC;


/*Finding countries with highest death rate per population*/
SELECT location,MAX(CAST(total_deaths AS INT)) AS max_deaths,
	ROUND(MAX((total_deaths/population))*100,2) AS percentage_deaths_from_population
FROM project_test..CovidDeaths 
WHERE location NOT LIKE continent
GROUP BY location
ORDER BY max_deaths DESC;

 
/* showing daily global numbers*/
SELECT date_column,
	SUM(new_cases) AS total_cases_per_day, 
	SUM(new_deaths) AS total_deaths_per_day,		
	(SUM(new_cases)/SUM(new_deaths))*100 AS percent_total_cases_of_deaths
FROM project_test..CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date_column
ORDER by date_column,total_cases_per_day DESC;

/*Summary numbers: totals of new_cases, new_deaths, percentage of total cases of deaths*/
SELECT  SUM(new_cases) AS total_cases, 
	SUM(new_deaths) AS total_deaths,	
	(SUM(new_cases)/SUM(new_deaths))*100 AS percent_total_cases_of_deaths
FROM project_test..CovidDeaths 
WHERE continent IS NOT NULL
ORDER by total_deaths DESC;


/* Step 4. Join the two tables, then use a window function to show the rolling total of vaccinations */
/* Joining the  two tables on two objects date and location */
SELECT *
FROM project_test..CovidDeaths AS CD
JOIN project_test..CovidVaccinations AS CV
ON CD.date_column= CV.date_column AND CD.location= CV.location;

/*Looking at the total population in the world who have been vaccinated,
using window function to partition by location */

SELECT CD.continent,CD.location,CD.date_column,CD.population,CV.new_vaccinations,
	SUM(CAST(CV.new_vaccinations AS INT)) OVER (PARTITION BY CD.location) AS rolling_tot_vaccinations
FROM project_test..CovidDeaths AS CD
JOIN project_test..CovidVaccinations AS CV
ON CD.date_column= CV.date_column AND CD.location= CV.location
WHERE CD.continent IS NOT NULL -- means that we are only looking at countries
ORDER BY CD.location,CD.date_column;

/*Step 5. Create Common Table Expression
with the rolling number of people vaccinated  over population  */
WITH vaccinate_tot AS (
SELECT CD.continent AS cont,CD.location as loc,CD.date_column,CD.population as population1,CV.new_vaccinations,
	SUM(CONVERT(INT,CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date_column) AS rolling_tot_vaccinations
FROM project_test..CovidDeaths AS CD
JOIN project_test..CovidVaccinations AS CV
ON CD.date_column= CV.date_column AND CD.location= CV.location
WHERE CD.continent IS NOT NULL)
SELECT  loc,population1,
	MAX(rolling_tot_vaccinations)as max_vax, 
	ROUND((MAX(rolling_tot_vaccinations)/population1)*100.0,2) AS percent_pop_vaccinated
FROM vaccinate_tot
GROUP BY loc,population1 
ORDER BY percent_pop_vaccinated DESC;


/* Step 6. Create temporary table of rolling total of vaccination*/

DROP TABLE IF EXISTS #percent_pop_vaccinated --in case table exists
CREATE TABLE  #percent_pop_vaccinated
	(continent nvarchar(255),
	location nvarchar(255),
	date_column datetime,
	population numeric,
	new_vaccinations numeric,
	rolling_tot_vaccinations numeric)
INSERT INTO  #percent_pop_vaccinated
SELECT CD.continent AS cont,CD.location as loc,CD.date_column,CD.population as population1,CV.new_vaccinations,
	SUM(CONVERT(INT,CV.new_vaccinations)) OVER (PARTITION BY CD.location ORDER BY CD.location, CD.date_column) AS rolling_tot_vaccinations
FROM project_test..CovidDeaths AS CD
JOIN project_test..CovidVaccinations AS CV
ON CD.date_column= CV.date_column AND CD.location= CV.location
WHERE CD.continent IS NOT NULL

SELECT *,
	ROUND((rolling_tot_vaccinations/Population)*100,2) AS percent_vax_over_pop
FROM #percent_pop_vaccinated
ORDER BY percent_vax_over_pop DESC
	

/* Step 7. Creating view to store data of rolling total of vacinationsfor later visualisations */
USE project_test;
DROP VIEW IF EXISTS percent_pop_vaccinated --a new view will be created each time then
/*View must be in the first line of the query,  in order to create the view in a given schema, it is needed to run the use command before it*/


CREATE VIEW percent_pop_vaccinated
AS
SELECT CD.continent AS cont,CD.location as loc,CD.date_column,CD.population as population1,CV.new_vaccinations,
	SUM(CONVERT(INT,CV.new_vaccinations)) OVER
	(PARTITION BY CD.location ORDER BY CD.location, CD.date_column) AS rolling_tot_vaccinations
FROM project_test..CovidDeaths AS CD
JOIN project_test..CovidVaccinations AS CV
ON CD.date_column= CV.date_column AND CD.location= CV.location
WHERE CD.continent IS NOT NULL;

SELECT *,
	ROUND((rolling_tot_vaccinations/population1)*100,2) AS percent_vax_over_pop
FROM percent_pop_vaccinated
ORDER BY percent_vax_over_pop DESC;





