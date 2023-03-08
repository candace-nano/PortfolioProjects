SELECT * FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, total_deaths, population
FROM covid_deaths
ORDER BY location, date

-- looking at total cases vs total deaths
-- shows the likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, ROUND((CAST(total_deaths AS NUMERIC)/CAST(total_cases AS NUMERIC)),2)*100 AS death_percentage
FROM covid_deaths
WHERE location ILIKE '%states%'
ORDER BY location, date

-- looking at total cases vs population
-- shows what percentage of population got COVID

SELECT location, date, total_cases, population, total_cases/CAST(population AS NUMERIC)*100 AS infection_percentage
FROM covid_deaths
ORDER BY location, date

-- looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(total_cases/CAST(population AS NUMERIC))*100 AS infection_percentage
FROM covid_deaths
GROUP BY location, population
ORDER BY infection_percentage DESC

-- showing countries with highest death count per population

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- LETS BREAK THINGS DOWN BY CONTINENT
-- showing continents with the higest death count

SELECT continent, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC

-- highlighting north america's death count by country

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent LIKE 'North America' AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- highlighting europe's death count by country

SELECT location, MAX(total_deaths) AS total_death_count
FROM covid_deaths
WHERE continent LIKE 'Europe' AND total_deaths IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- GLOBAL NUMBERS
-- by date

SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST(new_deaths AS NUMERIC))/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- total case rate, deaths, and death percentage across the globe

SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(CAST(new_deaths AS NUMERIC))/SUM(new_cases)*100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- looking at total population vs vaccinations

SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vaccinations.new_vaccinations, 
		SUM(covid_vaccinations.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_vaccinations
FROM covid_deaths
JOIN covid_vaccinations
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE
-- showing the total vaccination percentage per day per country

WITH population_vs_vaccination (continent, location, date, population, new_vaccinations, rolling_vaccinations) AS
(
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vaccinations.new_vaccinations, 
		SUM(covid_vaccinations.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_vaccinations
FROM covid_deaths
JOIN covid_vaccinations
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent IS NOT NULL
)
SELECT *, (CAST(rolling_vaccinations AS NUMERIC)/population)/2*100 AS vaccination_percentage
-- divided by 2 to account for each person vaccinated getting at least 2 doses (vaccines were recorded per every dose, not full vaccination status)
FROM population_vs_vaccination

-- showing the total vaccination percentage per country

WITH population_vs_vaccination (continent, location, date, population, new_vaccinations, rolling_vaccinations) AS
(
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vaccinations.new_vaccinations, 
		SUM(covid_vaccinations.new_vaccinations)OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_vaccinations
FROM covid_deaths
JOIN covid_vaccinations
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent IS NOT NULL
)
SELECT DISTINCT location, MAX((CAST(rolling_vaccinations AS NUMERIC)/population)/2*100) OVER (PARTITION BY location) AS total_vaccination_percentage_per_country
-- divided by 2 to account for each person vaccinated getting at least 2 doses (vaccines were recorded per every dose, not full vaccination status)
FROM population_vs_vaccination
GROUP BY location, rolling_vaccinations, population
ORDER BY location

-- creating view to store data for later visualizations

CREATE VIEW pop_vax AS
SELECT covid_deaths.continent, covid_deaths.location, covid_deaths.date, covid_deaths.population, covid_vaccinations.new_vaccinations, 
		SUM(covid_vaccinations.new_vaccinations) OVER (PARTITION BY covid_deaths.location ORDER BY covid_deaths.location, covid_deaths.date) AS rolling_vaccinations
FROM covid_deaths
JOIN covid_vaccinations
	ON covid_deaths.location = covid_vaccinations.location
	AND covid_deaths.date = covid_vaccinations.date
WHERE covid_deaths.continent IS NOT NULL

SELECT * FROM pop_vax

