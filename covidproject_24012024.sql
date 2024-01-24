SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjec..coviddeath$
ORDER BY 1,2

--Looking at total cases vs Total death
-- shows the likelihood of dying if you contact covid in your country
SELECT location, date, total_cases,total_deaths, 
(CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100 AS Deathpercentage
FROM PortfolioProjec..coviddeath$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Total cases vs Population
-- shows what percentage of population with covid
SELECT location, date, total_cases, population, 
(CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProjec..coviddeath$
WHERE location like '%states%'
ORDER BY 1,2

--Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
MAX((CONVERT(float, total_cases) / NULLIF(CONVERT(float, population), 0))) * 100 AS PercentPopulationInfected
FROM PortfolioProjec..coviddeath$
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProjec..coviddeath$
WHERE continent is NOT Null
GROUP BY location
ORDER BY TotalDeathCount DESC

-- let view data by continent
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProjec..coviddeath$
WHERE continent is NOT Null
GROUP BY continent
ORDER BY TotalDeathCount DESC

--showing continents with  the highest death count per population
SELECT continent, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProjec..coviddeath$
--WHERE location like %states%
WHERE continent is NOT Null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- Global Numbers
SELECT  date, SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS int)) AS total_deaths, SUM(cast(new_deaths AS int))/SUM(new_cases)*100 AS DeathPErcentage
FROM portfolioprojec..coviddeath$
--WHERE location like %states%
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

-- still trying the above
SELECT
    date,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM
    portfolioprojec..coviddeath$
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    date;

	-- Looking at total populations vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER by dea.location, dea.date) AS RollingCount, 
FROM PortfolioProjec..coviddeath$ dea
JOIN PortfolioProjec..covidVaccination$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Using CTE
WITH popvsVac (continent, location, date, population, new_vaccinations, RollingCount)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER by dea.location, dea.date) AS RollingCount
FROM PortfolioProjec..coviddeath$ dea
JOIN PortfolioProjec..covidVaccination$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingCount/population)*100
FROM popvsVac

-- TEMP table
DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
( continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER by dea.location, dea.date) AS RollingCount 
FROM PortfolioProjec..coviddeath$ dea
JOIN PortfolioProjec..covidVaccination$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (RollingCount/population)*100
FROM #PercentPopulationVaccinated

--creating view to store data for viz
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations AS bigint)) OVER (partition by dea.location ORDER by dea.location, dea.date) AS RollingCount 
FROM PortfolioProjec..coviddeath$ dea
JOIN PortfolioProjec..covidVaccination$ vac
	on dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3