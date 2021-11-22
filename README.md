# CovidDataFetcher

This project contains a variety of methods to help fetch and transform data
pertaining to COVID from the CDC.

## Up and Running

### Project Dependencies

This project runs on Elixir. First, install Elixir. Next, install the project dependencies with:

```
mix deps.get
```

### Configuring API Keys and Output

Copy `.example.env` as `.env` and complete the environment variables as needed
or desired.

You'll need an API app key from the CDC to fetch data. You can register for a
Socrata account and [here](https://data.cdc.gov/login). You'll then need to
create an app token. The same app token can be used on different datasets.

## Modules and Use

### Modules

All functions for handling data from the dataset are broken out into their own
modules. Currently:
* `CaseSurveillance` handles the ["COVID-19 Case Surveillance Public Use Data"](https://dev.socrata.com/foundry/data.cdc.gov/vbim-akqf) from the CDC's API
* `DataTracker` handles data downloaded from [COVID Data Tracker](https://covid.cdc.gov/covid-data-tracker/#datatracker-home)
* `DeathsByCause` handles the ["Monthly Provisional Counts of Deaths by Select Causes, 2020-2021"](https://data.cdc.gov/NCHS/Monthly-Provisional-Counts-of-Deaths-by-Select-Cau/9dzk-mvmi) from the CDC's API
* `Flu` handles data downloaded from ["Pneumonia, Influenza, and COVID-19 Mortality from the National Center for Health Statistics Mortality Surveillance System"](https://www.cdc.gov/flu/weekly/index.htm)
* `Vaers` handles data exported from the [CDC's WONDER VAERS data](https://wonder.cdc.gov/vaers.html)

### Use

First, from your terminal:
```
source .env
iex -S mix
```

#### COVID-19 Case Surveillance Public Use Data

First, register an app token with the CDC Socrata API.

To get combined cases and deaths by age:
```
CaseSurveillance.save_cases_by_age_data()
CaseSurveillance.save_deaths_by_age_data()
CaseSurveillance.get_combined_age_output()
```

To get deaths by underlying medical condition classification:
```
FetchCovidData.save_deaths_by_medcond()
```

#### COVID Data Tracker

First, download the daily and case chart data from the CDC. To transform the CSV
to JSON:
```
DataTracker.get_daily_deaths_output()
DataTracker.get_daily_cases_output()
```

#### Pneumonia, Influenza, and COVID-19 Mortality from the National Center for Health Statistics Mortality Surveillance System

First, download the chart data from the CDC. To transform the CSV to JSON:
```
ProcessCovidData.get_weekly_flu_output()
```

#### Monthly Provisional Counts of Deaths by Select Causes, 2020-2021

First, register an app token with the CDC Socrata API.

To get the monthly deaths by cause:
```
DeathsByCause.save_monthly_deaths_by_cause_2020_2021()
```


To calculate the deaths by cause for the year of 2020:
```
DeathsByCause.save_monthly_deaths_by_cause_2020_2021()
DeathsByCause.get_2020_causes_of_death()
```

#### VAERS Data

First, export the text file of the VAERs data from the CDC WONDER system. To
transform to JSON, manually delete the footer from the text file, then run:
```
Vaers.get_all_vaccine_events_by_year()
```