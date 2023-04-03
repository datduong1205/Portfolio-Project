-- SELECT * FROM covid_vaccinations ORDER BY 3, 4;

-- SELECT * FROM covid_deaths ORDER BY 3, 4;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, ((total_deaths::decimal / total_cases) * 100) AS death_percentage
FROM covid_deaths
WHERE location = 'Vietnam' AND continent IS NOT NULL
ORDER BY 1, 2;


-- Shows what percentage of population got Covid 
SELECT 
	location, 
	date, 
	population, 
	total_cases, 
	((total_cases::decimal / population) * 100) AS infected_percentage
FROM covid_deaths
WHERE location = 'Vietnam' AND continent IS NOT NULL 
ORDER BY 1, 2;


-- Looking at Countries with Highest Infection Rate compared to Population
SELECT 
	location, 
	population,
	MAX(total_cases) AS highest_infection_count, 
	MAX(((total_cases::decimal / population) * 100)) AS infected_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infected_percentage DESC;


-- Showing Countries with Highest Death Count per Population
SELECT 
	location,
	MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC;


-- Showing Countries with Highest Death Count per Population
SELECT 
	continent, 
	MAX(total_deaths) AS highest_death_count
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highest_death_count DESC;


-- Global Numbers 
SELECT 
	date,
	SUM(new_cases) AS total_new_cases,
	SUM(new_deaths) AS total_new_deaths,
	(SUM(new_deaths)::decimal / SUM(new_cases)) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;


-- Looking at Total Population vs Vaccinations
SELECT 
	d.continent, 
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM covid_deaths as d 
INNER JOIN covid_vaccinations as v
	ON  d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;


-- Use CTE
WITH pop_vs_vac AS (
	SELECT 
		d.continent, 
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
	FROM covid_deaths as d 
	INNER JOIN covid_vaccinations as v
		ON  d.location = v.location 
		AND d.date = v.date
	WHERE d.continent IS NOT NULL
	ORDER BY 2, 3
)
SELECT *, (rolling_people_vaccinated::decimal / population ) * 100 AS vaccinated_percentage
FROM pop_vs_vac;


-- TEMP TABLE
DROP TABLE IF EXISTS percent_population_vaccinated;

CREATE TABLE percent_population_vaccinated (
	continent varchar(255),
	location varchar(255),
	date timestamp,
	population numeric,
	new_vaccination numeric,
	rolling_people_vaccinated numeric
);

INSERT INTO percent_population_vaccinated
SELECT 
	d.continent, 
	d.location,
	d.date,
	d.population,
	v.new_vaccinations,
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_people_vaccinated
FROM covid_deaths as d 
INNER JOIN covid_vaccinations as v
	ON  d.location = v.location 
	AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2, 3;

SELECT *, (rolling_people_vaccinated::decimal / population ) * 100 AS vaccinated_percentage
FROM percent_population_vaccinated;


-- Creating View to Store Data for later Visualizations
CREATE VIEW percent_new_deaths_vs_new_cases AS 
SELECT 
	date,
	SUM(new_cases) AS total_new_cases,
	SUM(new_deaths) AS total_new_deaths,
	(SUM(new_deaths)::decimal / SUM(new_cases)) * 100 AS death_percentage
FROM covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;
