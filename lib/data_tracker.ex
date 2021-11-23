defmodule DataTracker do
  @moduledoc """
  DataTracker contains methods to handle data downloaded from the CDC's
  [COVID Data Tracker](https://covid.cdc.gov/covid-data-tracker/#datatracker-home)
  """
  @doc """
  Converts a CSV of daily cases from the [CDC provisional data](https://covid.cdc.gov/covid-data-tracker/#trends_dailytrendscases)
  to a JSON of monthly cases. The daily cases CSV should be downloaded first. The
  CSV input location and JSON output location are environment variables.

  A sample output:
  [
    {
      "state":"United States",
      "seven_day_moving_average":"0",
      "new_cases":"1",
      "historic_cases":"0",
      "date":"Jan 23 2020"
    },
    ...
  ]
  """
  def get_daily_cases_output() do
    get_daily_output(
      System.get_env("DAILY_CASES_CSV"),
      [:state, :date, :new_cases, :seven_day_moving_average, :historic_cases],
      System.get_env("DAILY_CASES_OUTPUT")
    )
  end

  @doc """
  Converts a CSV of daily deaths from [CDC provisional data](https://covid.cdc.gov/covid-data-tracker/#trends_dailytrendscases)
  to a JSON of monthly deaths. The daily deaths CSV should be downloaded first.
  The CSV input location and JSON output location are environment variables.

  A sample output:
  [
    {
      "state":"United States",
      "seven_day_moving_average":"0",
      "new_deaths":"0",
      "historic_deaths":"0",
      "date":"Jan 23 2020"
    }
    ...
  ]
  """
  def get_daily_deaths_output() do
    get_daily_output(
      System.get_env("DAILY_DEATHS_CSV"),
      [:state, :date, :new_deaths, :seven_day_moving_average, :historic_deaths],
      System.get_env("DAILY_DEATHS_OUTPUT")
    )
  end

  @doc """
  Takes the cases or deaths CSV input file path, expected CSV headers, and the
  JSON output file path. The CSV input is transformed to JSON as an array of
  objects.
  """
  def get_daily_output(csv_file, headers, json_file) do
    acc =
      File.stream!(csv_file)
      |> Stream.drop(3)
      |> CSV.decode(headers: headers)
      |> Enum.map(fn row ->
        {:ok, data} = row
        data
      end)
      |> Enum.map(fn data ->
        {:ok, parsed} = Timex.parse(data.date, "%b %e %Y", :strftime)
        %{data | date: parsed}
      end)
      |> Enum.sort_by(&Map.fetch!(&1, :date), Date)
      |> Enum.map(fn data ->
        {:ok, formatted} = Timex.format(data.date, "%b %e %Y", :strftime)
        %{data | date: formatted}
      end)
      |> Poison.encode!()

    File.write(json_file, acc)
  end
end
