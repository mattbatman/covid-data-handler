defmodule Flu do
  @moduledoc """
  Flu handles data from the chart hosted on the CDC's website for [Pneumonia,
  Influenza, and COVID-19 Mortality from the National Center for Health Statistics
  Mortality Surveillance System](https://www.cdc.gov/flu/weekly/index.htm). The
  chart is updated weekly.
  """

  @doc """
  Transforms the CDC CSV download data to a JSON file. The local location of the
  CSV download should be specified as an environment variable first, as well as
  the desired JSON output.

  A sample JSON output:
  [
    {
      "year":"2013",
      "week":"40",
      "threshold":"6.77011",
      "pneumonia_influenza_or_COVID_19_deaths":"3143",
      "pneumonia_deaths":"3140",
      "percent_of_deaths_due_to_pneumonia_influenza_or_COVID_19":"6.6179567085",
      "percent_of_deaths_due_to_pneumonia_and_influenza":"6.6179567085",
      "influenza_deaths":"3",
      "expected":"6.36132",
      "all_deaths":"47492",
      "COVID_19_deaths":"0"
    },
    ...
  ]
  """
  def get_weekly_flu_output do
    headers = [
      :year,
      :week,
      :percent_of_deaths_due_to_pneumonia_and_influenza,
      :percent_of_deaths_due_to_pneumonia_influenza_or_COVID_19,
      :expected,
      :threshold,
      :all_deaths,
      :pneumonia_deaths,
      :influenza_deaths,
      :COVID_19_deaths,
      :pneumonia_influenza_or_COVID_19_deaths
    ]

    acc =
      File.stream!(System.get_env("WEEKLY_FLU_DEATHS_CSV"))
      |> Stream.drop(1)
      |> CSV.decode(headers: headers)
      |> Enum.map(fn row ->
        {:ok, data} = row
        data
      end)
      |> Poison.encode!()

    File.write(System.get_env("WEEKLY_FLU_DEATHS_OUTPUT"), acc)
  end
end
