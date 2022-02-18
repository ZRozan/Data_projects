
-- Total Death Percentage

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS DECIMAL)) AS TotalDeaths, FORMAT((SUM(CAST(new_deaths AS DECIMAL))/SUM(new_cases))*100, '0.00''%') as DeathPercentage
FROM Covid_Portfolio_Project..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- total cases vs total deaths

select location, date, total_cases, total_deaths, FORMAT((total_deaths/total_cases)*100, '0.00') as DeathPercentage 
From Covid_Portfolio_Project..covid_deaths
Where continent IS NOT NULL
	-- AND location like '%brazil%'
Order by 1, 2;

-- total cases vs population

select location, date, population, total_cases, FORMAT((total_cases/population)*100, '0.00') as PopulationInfectedPercentage 
From Covid_Portfolio_Project..covid_deaths
where continent is not NULL
	-- AND location like '%brazil%'
Order by 1, 2;

-- countries with highest infection rates compared by population

Select location, population, MAX(total_cases) as HighestInfectionCount, FORMAT(MAX((total_cases/population)*100), '00.00') as PopulationInfectedPercentage 
From Covid_Portfolio_Project..covid_deaths
where continent is not NULL
Group by location, population
Order by PopulationInfectedPercentage DESC;

-- countries with highest death count per population

Select location, MAX(cast(total_deaths as decimal)) AS TotalDeathCount
From Covid_Portfolio_Project..covid_deaths
where continent is not NULL
Group by location 
Order by TotalDeathCount DESC;

-- total death count by continent

Select location, MAX(cast(total_deaths as decimal)) AS TotalDeathCount
From Covid_Portfolio_Project..covid_deaths
Where continent is NULL 
AND location not in ('World', 'European Union', 'International')
AND location not like '%income%'
Group by location 
Order by TotalDeathCount DESC;

-- Global numbers per day

Select FORMAT(date, 'yyyy-MM-dd') AS Date, SUM(total_cases) as TotalCasesGlobal, SUM(CAST(total_deaths AS decimal)) AS TotalDeathsGlobal, 
	FORMAT((SUM(CAST(total_deaths AS decimal))/SUM(total_cases))*100, '0.00') AS DeathPercentage
From Covid_Portfolio_Project..covid_deaths
Where continent is NULL AND location not like '%income%'
Group by date 
Order by Date;

-- Global population vaccinated

SELECT dea.continent, dea.location, FORMAT(dea.date, 'yyyy-MM-dd') AS Date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(DECIMAL, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_Project..covid_deaths dea
JOIN Covid_Portfolio_Project..covid_vaccinations vac
	ON dea.date = vac.date 
	AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3;

-- CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(DECIMAL, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_Project..covid_deaths dea
JOIN Covid_Portfolio_Project..covid_vaccinations vac
	ON dea.date = vac.date 
	AND dea.location = vac.location
WHERE dea.continent IS NOT NULL
)

SELECT *, FORMAT((RollingPeopleVaccinated/population)*100, '0.00') AS VaccinationPercentage
FROM PopVsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #PercentpopulationVaccinatedOne
CREATE TABLE #PercentpopulationVaccinatedOne
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population decimal,
new_vaccinations decimal,
RollingPeopleVaccinated decimal,
)

INSERT INTO #PercentpopulationVaccinatedOne
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(DECIMAL, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_Project..covid_deaths dea
JOIN Covid_Portfolio_Project..covid_vaccinations vac
	ON dea.date = vac.date 
	AND dea.location = vac.location
WHERE dea.continent IS NOT NULL;
--ORDER BY 2, 3

SELECT *, FORMAT((RollingPeopleVaccinated/population)*100, '0.00')
FROM #PercentpopulationVaccinatedOne;


-- CREATE VIEWS FOR LATER

CREATE VIEW PercentpopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(DECIMAL, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM Covid_Portfolio_Project..covid_deaths dea
JOIN Covid_Portfolio_Project..covid_vaccinations vac
	ON dea.date = vac.date 
	AND dea.location = vac.location
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentpopulationVaccinated;