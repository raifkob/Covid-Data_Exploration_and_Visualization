-- Examining the tables.
SELECT	*
FROM sqldemo..coviddeaths
--WHERE continent is not null
ORDER BY location, date

SELECT	*
FROM sqldemo..covidvaccinations
WHERE continent is not null
ORDER BY location, date

-- Total cases each day sorted by country and date
SELECT location,date,population, total_cases, new_cases,total_deaths
FROM coviddeaths
WHERE continent is not null
ORDER BY location, date

-- Percentage of death in India each day.
SELECT location,date,population, total_cases,total_deaths, (total_deaths/total_cases)*100 AS percentage_death
FROM coviddeaths
where location = 'india'
order by location, date

-- Percentage of death in UAE each day.
SELECT location,date,population, total_cases,total_deaths, (total_deaths/total_cases)*100 AS percentage_death
FROM coviddeaths
where location like '%Emirates%'
order by location, date

-- Percentage of total cases vs population in India
SELECT	 location, date, population,total_cases, (total_cases/population)*100 AS Infected_percentage
FROM coviddeaths
where location = 'india' 
ORDER BY location, date	

-- Percentage of total cases vs population in UAE	
SELECT	 location, date, population,total_cases, (total_cases/population)*100 AS  Infected_population_percentage
FROM coviddeaths
where location like '%Emirates%' 
ORDER BY location, date	


--Countries with highest infection rate compared to population
SELECT	 location, population, Max(total_cases) AS Highest_infectioncount, 
         Max((total_cases/population))*100 AS Infected_population_percentage
FROM coviddeaths
WHERE continent is NOT null
GROUP BY location, population
ORDER BY Infected_population_percentage DESC

--Countries with highest death rate compared to population
SELECT	 location, population, MAX(CAST (total_deaths as INT)) AS Highest_deathcount, 
         MAX((total_deaths/population))*100 AS Death_population_percentage
FROM coviddeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY Death_population_percentage DESC


-- countries with highest cases and deaths 
SELECT	 location,MAX(total_cases) AS totalcases,
		 MAX(CAST (total_deaths as INT)) AS totaldeaths   
FROM coviddeaths
WHERE continent is NOT NULL
GROUP BY location
ORDER BY location

-- Continent with highest cases and deaths 
SELECT	 continent,MAX(total_cases) AS totalcases,
		 MAX(CAST (total_deaths as INT)) AS totaldeaths   
FROM coviddeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY continent 

--global cases vs deaths each day

SELECT date, sum(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths,
		SUM(cast(new_deaths as int))/sum(new_cases)*100 As DeathPercentage 
FROM coviddeaths
WHERE continent is not null
GROUP BY date
ORDER BY date DESC 

-- total populations vs vaccinations 

SELECT dea.continent,dea.location,dea.date, dea.population, vac.new_vaccinations
FROM coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
order by location, date

--rolling count of vaccinations daily each country.

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(cast (vac.new_vaccinations as bigint)) OVER 
	(partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
	--(rolling_count_vaccinations/dea.population)*100 AS Vaccinated_percentage_populations
FROM coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null
order by location, date

-- using CTE to find rolling percentage of vaccination each country compare to populations

With PopvsVac ( continent, location, date, population, new_vaccinations, rolling_count_vaccinations )
as 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(cast (vac.new_vaccinations as bigint)) OVER 
	(partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations

FROM coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location 
	and dea.date = vac.date

WHERE dea.continent is not null
)

SELECT * , (rolling_count_vaccinations/population)*100 as rolling_Vaccinated_percentage_populations
FROM PopvsVac


-- Using Temp Table to find daily percentage of vaccination each country compare to populations


DROP TABLE IF EXISTS #percent_population_vaccinated
Create Table #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_count_vaccinations numeric

)
INSERT INTO #percent_population_vaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations	
	,SUM(cast (vac.new_vaccinations as bigint)) OVER 
	(partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations

FROM coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location 
	and dea.date = vac.date

select *, ( rolling_count_vaccinations/population)*100 as rollingvaccination_percent
from #percent_population_vaccinated


-- Creating views of above table

CREATE VIEW perc_population_vaccinated AS

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
	,SUM(cast (vac.new_vaccinations as bigint)) OVER 
	(partition by dea.location order by dea.location, dea.date) as rolling_count_vaccinations
FROM coviddeaths as dea
join covidvaccinations as vac
	on dea.location = vac.location 
	and dea.date = vac.date
WHERE dea.continent is not null

--examining new table created above using View.
SELECT *
FROM perc_population_vaccinated
