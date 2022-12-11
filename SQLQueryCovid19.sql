
Select *
From Covid19_deaths..Covid19
order by 3,4

--Select *
--From Covid19_deaths..Covidvaccinated
--order by 3,4

-- Select data that we are going to be using
Select location, date, total_cases, new_cases, total_deaths, population 
From Covid19_deaths..Covid19
order by 1,2

--Looking at total Cases VS. total Deaths
-- Shows Liklihood of dying if you contract covid in your country
--Looking at total cases vs population
Select location, date, total_cases,total_deaths, population, (total_deaths/total_cases)*100 As DeathPercentages,
(total_cases/population)*100 As PercentPopulationInfected
From Covid19_deaths..Covid19
Where location = 'united states'
order by 1, 2

-- Looking at countries with highest Infection rate compared to population
Select location, population, Max(total_cases) As HighestInfectionCount,  Max((total_cases/population))*100 As PercentPopulationInfected
From Covid19_deaths..Covid19
Group by location, population
order by  PercentPopulationInfected desc

--Showing Countries With Highest Death Count per Population
Select Location, MAX(cast (total_deaths As int)) As TotalDeathCount
From Covid19_deaths..Covid19
Where continent is not null
Group by Location
order by TotalDeathCount desc

--Showing Continents With Highest Death Count per Population
Select continent, MAX(cast (total_deaths As int)) As TotalDeathCount
From Covid19_deaths..Covid19
Where continent is not null
Group by continent
order by TotalDeathCount desc

-- Global Numbers
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeath, SUM(cast(new_deaths as int))/SUM(new_cases) *100 AS DeathPercentage
FROM dbo.Covid19
--where location like '%states%'
Where continent is not null
--group by date
order by 1,2


-- Looking at total population vs total Vaccination
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as bigint )) OVER (partition by death.location order by death.location, death.date) AS RollingPeopleVaccinated
FROM dbo.Covid19  death 
JOIN dbo.Covidvaccinated vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
order by 2,3


-- USE CTE
-- Looking at total population vs total Vaccination
WITH PopvsVacc ( continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as bigint )) OVER (partition by death.location order by death.location, death.date) AS RollingPeopleVaccinated
FROM dbo.Covid19  death 
JOIN dbo.Covidvaccinated vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--order by 2,3
)
SELECT * , (RollingPeopleVaccinated/population)*100 As
FROM PopvsVacc

--Using Temp Table to perform Calculation on Partition By in previous query
DRop Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location  nvarchar(255),
Date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as bigint )) OVER (partition by death.location order by death.location, death.date) AS RollingPeopleVaccinated
FROM dbo.Covid19  death 
JOIN dbo.Covidvaccinated vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null
--order by 2,3
SELECT * , (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated

-- Creating view to store data for later visualization
Create view PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vacc.new_vaccinations,
SUM(CAST(vacc.new_vaccinations as bigint )) OVER (partition by death.location order by death.location, death.date) AS RollingPeopleVaccinated
FROM dbo.Covid19  death 
JOIN dbo.Covidvaccinated vacc
	ON death.location = vacc.location
	and death.date = vacc.date
WHERE death.continent is not null