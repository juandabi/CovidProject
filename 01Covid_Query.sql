SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

SELECT *
FROM PortfolioProject..CovidVaccinations
ORDER BY 3, 4

-- Select data that we are going to be using
SELECT location, DATE, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%United states'
	AND DATE LIKE '%2020%'
ORDER BY 2

-- Looking at Total cases vs Total deaths
-- Show likelihood of dying if you contract covid in your country
SELECT location, DATE, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%states'
	AND DATE LIKE '%2020%'
ORDER BY 1, 2

-- Looking at the total_Cases vs population
-- Show what percentage of population got Covid
SELECT location, DATE, population, total_cases, (total_cases / population) AS PopulationPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Colombia'
	AND DATE LIKE '%2020%'
ORDER BY 1, 2

-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC

-- Showing Countries with Highest Death Count per Population
SELECT location, MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%States'
	AND continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Find by continent 
SELECT continent, max(total_Deaths) AS TotalDeathCountByContinent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCountByContinent DESC

-- LET´S BREAK THINGS DOWN BY CONTINENT
-- Group by location then find Max in continent
SELECT continent, location, max(total_Deaths) AS TotalDeathCountByContinent
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY continent, location
ORDER BY TotalDeathCountByContinent DESC

----showing continents with the highest death count per population
SELECT continent, sum(MaxtotalDeathCount) AS TotalDeathCountByContinent
FROM (
	SELECT continent, location, max(total_Deaths) AS MaxtotalDeathCount
	FROM PortfolioProject..CovidDeaths
	WHERE continent IS NOT NULL
	GROUP BY continent, location
	) AS subquery
GROUP BY continent
ORDER BY TotalDeathCountByContinent DESC

--GLOBAL NUMBERS
SELECT DATE, sum(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / sum(new_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
	AND new_cases > 0
GROUP BY DATE
ORDER BY 1, 2

---- Global numbers total in the world
SELECT sum(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths) / sum(new_cases)) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
	AND new_cases > 0
ORDER BY 1, 2

-- looking at total population vs vaccinations
SELECT dea.continent, dea.location, dea.DATE, population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

-- looking at total population vs vaccinations (add funtion to do a rolling count to get total vaccinations)
SELECT dea.continent, dea.location, dea.DATE, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location, dea.DATE
		) AS RollingPeopleVaccinated
--		,(RollingPeopleVaccinated/100)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3
-- USE CTE
WITH PopvsVac(Continent, Location, DATE, Population, New_Vaccinations, RollingPeopleVaccinated) AS (
		SELECT dea.continent, dea.location, dea.DATE, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (
				PARTITION BY dea.location ORDER BY dea.location, dea.DATE
				) AS RollingPeopleVaccinated
		--		,(RollingPeopleVaccinated/100)*100
		FROM PortfolioProject..CovidDeaths dea
		JOIN PortfolioProject..CovidVaccinations vac
			ON dea.location = vac.location
				AND dea.DATE = vac.DATE
		WHERE dea.continent IS NOT NULL
		)

--ORDER BY 1, 2, 3
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS RollingPercentage
FROM PopvsVac
ORDER BY 1, 2, 3

-- TEMP TABLE
DROP TABLE

IF EXISTS #PercentPopulationVaccinated
	CREATE TABLE #PercentPopulationVaccinated (Continent NVARCHAR(255), Location NVARCHAR(255), DATE DATETIME, Population NUMERIC, New_vaccinations NUMERIC, RollingPeopleVaccinated NUMERIC)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.DATE, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location, dea.DATE
		) AS RollingPeopleVaccinated
--		,(RollingPeopleVaccinated/100)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

SELECT *, (RollingPeopleVaccinated / Population) * 100 AS RollingPercentage
FROM #PercentPopulationVaccinated
ORDER BY 1, 2, 3

-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW PercentPopulationVaccinated
AS
SELECT dea.continent, dea.location, dea.DATE, population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (
		PARTITION BY dea.location ORDER BY dea.location, dea.DATE
		) AS RollingPeopleVaccinated
--		,(RollingPeopleVaccinated/100)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
		AND dea.DATE = vac.DATE
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
