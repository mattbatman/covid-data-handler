defmodule FetchCovidData do
  @moduledoc """
  `FetchCovidData` fetches data from the CDC API and writes it to a JSON file.
  """

  @doc """
  Fetches and writes cases by age data to JSON.
  """
  def save_cases_by_age_data() do
    fetch_cases_by_age()
    |> handle_fetch(System.get_env("CASES_BY_AGE_OUTPUT"))
  end

  @doc """
  Fetches and writes deaths by age data to JSON.
  """
  def save_deaths_by_age_data() do
    fetch_deaths_by_age()
    |> handle_fetch(System.get_env("DEATHS_BY_AGE_OUTPUT"))
  end

  @doc """
  Fetches and writes deaths count by underlying medical condition (yes, no, missing, unknown) to JSON.
  """
  def save_deaths_by_medcond() do
    fetch_deaths_by_medcond()
    |> handle_fetch(System.get_env("DEATHS_BY_MEDCOND_OUTPUT"))
  end

  @doc """
  Takes an HTTPPoison response and a file path and name and writes the to the file path, if successful.
  """
  def handle_fetch(resp, output) do
    case resp do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        File.write(output, body)

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Not found :(")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end

  @doc """
  Fetches the total number of deaths for each underlying medical condition category.
  """
  def fetch_deaths_by_medcond() do
    fetch_cdc_data("?$select=medcond_yn,count(*)&$where=death_yn='Yes'&$group=medcond_yn")
  end

  @doc """
  Fetches cases by age from the CDC API.
  """
  def fetch_cases_by_age() do
    fetch_cdc_data("?$select=age_group,count(*)&$group=age_group")
  end

  @doc """
  Fetches deaths by age from the CDC API.
  """
  def fetch_deaths_by_age() do
    fetch_cdc_data("?$select=age_group,count(*)&$group=age_group&$where=death_yn='Yes'")
  end

  @doc """
  Takes a query string and calls CDC API.
  """
  def fetch_cdc_data(query) do
    HTTPoison.get("https://data.cdc.gov/resource/vbim-akqf.json#{query}",
      "X-App-Token": cdc_app_token(),
      "content-type": "application/json"
    )
  end

  defp cdc_app_token() do
    System.get_env("CDC_APP_TOKEN")
  end
end
