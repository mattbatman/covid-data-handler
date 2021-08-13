# CovidDataFetcher

This project grabs data from the CDC's API for the *COVID-19 Case Surveillance Public Use Data* data set.

## Up and Running

### Project Dependencies

This project runs on Elixir. Install Elixir, and then the project dependencies with:

```
mix deps.get
```

### Configuring API Keys and Output

Copy `.example.env` as `.env` and complete the environment variables. You'll need an API app key from the CDC for the [COVID-19 Case Surveillance Public Use Data](https://dev.socrata.com/foundry/data.cdc.gov/vbim-akqf). You'll also need to configure the output file names and directories.

### Use

The module `FetchCovidData` is responsible for interactions with the API. The module `ProcessCovidData` performs data transformations on the JSON files already created from `FetchCovidData`.

From your terminal:
```
source .env
iex -S mix
FetchCovidData.save_cases_by_age_data()
FetchCovidData.save_deaths_by_age_data()
ProcessCovidData.get_combined_age_output()
```
