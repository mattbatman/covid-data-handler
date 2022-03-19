defmodule CaseSurveillance do
  @moduledoc """
  CaseSurveillance handles interactions with the CDC's API dataset called,
  ["COVID-19 Case Surveillance Public Use Data."](https://dev.socrata.com/foundry/data.cdc.gov/vbim-akqf)
  """

  @doc """
  Opens the cases and deaths by age group files, combines the data, and writes
  the combined data to a new, single file.

  The case and death data should be saved first with environment variables of
  CASES_BY_AGE_OUTPUT and DEATHS_BY_AGE_OUTPUT. The save_cases_by_age_data and
  save_deaths_by_age_data functions can be used to get this data.

  Sample output:
  [
    {
      "deaths":"406",
      "cases":"2266108",
      "age_group":"0 - 9 Years"
    },
    ...
  ]
  """
  def get_combined_age_output() do
    with {:ok, cases_body} <- File.read(System.get_env("CASES_BY_AGE_OUTPUT")),
         {:ok, cases_json} <- Poison.decode(cases_body) do
      with {:ok, deaths_body} <- File.read(System.get_env("DEATHS_BY_AGE_OUTPUT")),
           {:ok, deaths_json} <- Poison.decode(deaths_body) do
        combined_age_data = get_combined_age_data(cases_json, deaths_json) |> Poison.encode!()
        File.write(System.get_env("COMBINED_BY_AGE_OUTPUT"), combined_age_data)
      end
    end
  end

  @doc """
  Takes the case and death by age data and returns a list of maps of the combined
  data. This is a helper function for get_combined_age_output.
  """
  def get_combined_age_data(cases_data, deaths_data) do
    cases_keys = Enum.map(cases_data, fn x -> x["age_group"] end)
    deaths_keys = Enum.map(deaths_data, fn x -> x["age_group"] end)

    combined_data =
      Enum.concat(cases_keys, deaths_keys)
      |> Enum.uniq()
      |> Enum.reduce([], fn age_group, acc ->
        %{"count" => deaths} =
          Enum.find(deaths_data, %{"count" => 0}, fn d -> d["age_group"] == age_group end)

        %{"count" => cases} =
          Enum.find(cases_data, %{"count" => 0}, fn d -> d["age_group"] == age_group end)

        [
          %{
            "age_group" => age_group,
            "cases" => cases,
            "deaths" => deaths
          }
          | acc
        ]
      end)

    combined_data
  end

  @doc """
  Fetches case count by age from COVID-19 Case Surveillance Public Use Data API
  data and writes to the JSON file and directory specified in the
  CASES_BY_AGE_OUTPUT environment variable.

  Sample output:
  [
    {
      "age_group":"0 - 9 Years",
      "count":"2266108"
    },
    ...
  ]
  """
  def save_cases_by_age_data() do
    fetch_cases_by_age()
    |> Fetch.handle_fetch(System.get_env("CASES_BY_AGE_OUTPUT"))
  end

  @doc """
  Fetches deaths by age from COVID-19 Case Surveillance Public Use Data API
  data and writes to the JSON file and directory specified in the
  DEATHS_BY_AGE_OUTPUT environment variable.

  Sample output:
  [
    {
      "age_group":"0 - 9 Years",
      "count":"406"
    },
    ...
  ]
  """
  def save_deaths_by_age_data() do
    fetch_deaths_by_age()
    |> Fetch.handle_fetch(System.get_env("DEATHS_BY_AGE_OUTPUT"))
  end

  @doc """
  Fetches deaths count by underlying medical condition from COVID-19 Case
  Surveillance Public Use Data API and writes to the JSON file specified in the
  DEATHS_BY_MEDCOND_OUTPUT environment variable.

  Sample output:
  [
    {
      "medcond_yn": "Yes",
      "count": "116160"
    },
    ...
  ]
  """
  def save_deaths_by_medcond() do
    fetch_deaths_by_medcond()
    |> Fetch.handle_fetch(System.get_env("DEATHS_BY_MEDCOND_OUTPUT"))
  end

  @doc """
  Fetches the total number of deaths for each underlying medical condition
  category from COVID-19 Case Surveillance Public Use Data.
  """
  def fetch_deaths_by_medcond() do
    fetch_cdc_data("?$select=medcond_yn,count(*)&$where=death_yn='Yes'&$group=medcond_yn")
  end

  @doc """
  Counts all cases by age in COVID-19 Case Surveillance Public Use Data.

  Sample response:
  [
    {
      "age_group": "0 - 9 Years",
      "count": "2266108"
    },
    ...
  ]
  """
  def fetch_cases_by_age() do
    fetch_cdc_data("?$select=age_group,count(*)&$group=age_group")
  end

  @doc """
  Fetches deaths by age from COVID-19 Case Surveillance Public Use Data.

  Sample response:
  [
    {
      "age_group": "10 - 19 Years",
      "count": "862"
    },
  ]
  """
  def fetch_deaths_by_age() do
    fetch_cdc_data("?$select=age_group,count(*)&$group=age_group&$where=death_yn='Yes'")
  end

  @doc """
  Takes a query string and calls the CDC API for the dataset called,
  ["COVID-19 Case Surveillance Public Use Data."](https://dev.socrata.com/foundry/data.cdc.gov/vbim-akqf)
  An app token registered with the CDC API is required to use this function.
  """
  def fetch_cdc_data(query) do
    HTTPoison.get("https://data.cdc.gov/resource/vbim-akqf.json#{query}",
      "X-App-Token": System.get_env("CDC_APP_TOKEN"),
      "content-type": "application/json"
    )
  end
end
