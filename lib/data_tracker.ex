defmodule DataTracker do
  @cases_headers [:state, :date, :new_cases, :seven_day_moving_average, :historic_cases]
  @deaths_headers [:state, :date, :new_deaths, :seven_day_moving_average, :historic_deaths]
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
    File.write(
      System.get_env("DAILY_CASES_OUTPUT"),
      get_daily_encoded_data(
        System.get_env("DAILY_CASES_CSV"),
        @cases_headers
      )
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
    File.write(
      System.get_env("DAILY_DEATHS_OUTPUT"),
      get_daily_encoded_data(
        System.get_env("DAILY_DEATHS_CSV"),
        @deaths_headers
      )
    )
  end

  @doc """
  Takes the cases or deaths CSV input file path, and the expected CSV headers.
  The CSV input is transformed to a list of maps.
  """
  def get_daily_data(csv_file, headers) do
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
      {:ok, formatted} = Timex.format(data.date, "%b %e %y", :strftime)
      %{data | date: formatted}
    end)
  end

  @doc """
  Takes the cases or deaths CSV input file path, and the expected CSV headers.
  The CSV input is transformed to encoded JSON as an array of objects and returned.
  """
  def get_daily_encoded_data(csv_file, headers) do
    get_daily_data(csv_file, headers)
    |> Poison.encode!()
  end

  @doc """
  Takes the case and death CSV, calculates the CFR for each day from the seven
  day moving average, and writes an encoded JSON file as an array of objects.
  """
  def get_seven_day_moving_average_cfr_output() do
    cases_data =
      get_daily_data(
        System.get_env("DAILY_CASES_CSV"),
        @deaths_headers
      )

    deaths_data =
      get_daily_data(
        System.get_env("DAILY_DEATHS_CSV"),
        @deaths_headers
      )

    cfr_data =
      Enum.map(cases_data, fn %{
                                date: date,
                                seven_day_moving_average: cases_seven_day_moving_average
                              } ->
        %{seven_day_moving_average: deaths_seven_day_moving_average} =
          Enum.find(deaths_data, fn %{date: deaths_date} -> deaths_date == date end)

        {deaths_float, _} = Float.parse(deaths_seven_day_moving_average)
        {cases_float, _} = Float.parse(cases_seven_day_moving_average)

        cfr =
          try do
            deaths_float / cases_float
          rescue
            _ ->
              0.0
          end

        %{
          date: date,
          cfr: cfr
        }
      end)
      |> Poison.encode!()

    File.write(
      System.get_env("SEVEN_DAY_MOVING_AVE_CFR_OUTPUT"),
      cfr_data
    )
  end
end
