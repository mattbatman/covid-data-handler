defmodule ProcessCovidData do
  @moduledoc """
  `ProcessCovidData` transforms data as needed after being fetched from the CDC API.
  """

  @doc """
  Through an environment variable input, transforms a .txt of VAERS CDC wonder data
  for reported vaccine deaths by year and writes as a JSON file. The disclaimers
  and links at the bottom of the file .txt file should be manually deleted first.
  """
  def get_vaccine_deaths_by_year() do
    json_keys = [
      :year_reported,
      :year_reported_code,
      :events_reported,
      :percent
    ]

    encoded_json_data =
      File.stream!(System.get_env("VACCINE_DEATHS_BY_YEAR_INPUT"))
      |> Enum.map(fn x ->
        String.split(x, "\n", trim: true)
      end)
      |> List.flatten()
      |> Enum.map(fn x ->
        String.split(x, "\t", trim: true)
        |> Enum.map(fn y ->
          String.trim(y, "\"")
        end)
      end)
      |> Enum.drop(1)
      |> Enum.map(fn x ->
        Enum.zip(json_keys, x)
        |> Enum.into(%{})
      end)
      |> Poison.encode!()

    File.write(System.get_env("VACCINE_DEATHS_BY_YEAR_OUTPUT"), encoded_json_data)
  end

  def get_all_vaccine_events_by_year() do
    json_keys = [
      :event_category,
      :event_category_code,
      :year_reported,
      :year_reported_code,
      :events_reported,
      :percent
    ]

    encoded_json_data =
      File.stream!(System.get_env("VACCINE_EVENTS_BY_YEAR_INPUT"))
      |> Enum.map(fn x ->
        String.split(x, "\n", trim: true)
      end)
      |> List.flatten()
      |> Enum.map(fn x ->
        String.split(x, "\t", trim: true)
        |> Enum.map(fn y ->
          String.trim(y, "\"")
        end)
      end)
      |> Enum.drop(1)
      |> Enum.map(fn x ->
        Enum.zip(json_keys, x)
        |> Enum.into(%{})
      end)
      |> Poison.encode!()

    File.write(System.get_env("VACCINE_EVENTS_BY_YEAR_OUTPUT"), encoded_json_data)
  end

  @doc """
  Calculates the 2021 and 2021 annual deaths by select causes from saved monthly
  2020 and 2021 deaths by select causes.
  """
  def get_2020_causes_of_death() do
    saved_file_path = System.get_env("MONTHLY_DEATHS_BY_CAUSE_20_21_RAW")

    starter = %{
      "all_cause" => 0,
      "natural_cause" => 0,
      "septicemia" => 0,
      "malignant_neoplasms" => 0,
      "diabetes_mellitus" => 0,
      "alzheimer_disease" => 0,
      "influenza_and_pneumonia" => 0,
      "chronic_lower_respiratory" => 0,
      "other_diseases_of_respiratory" => 0,
      "nephritis_nephrotic_syndrome" => 0,
      "symptoms_signs_and_abnormal" => 0,
      "diseases_of_heart" => 0,
      "cerebrovascular_diseases" => 0,
      "accidents_unintentional" => 0,
      "motor_vehicle_accidents" => 0,
      "intentional_self_harm_suicide" => 0,
      "assault_homicide" => 0,
      "drug_overdose" => 0,
      "covid_19_multiple_cause_of" => 0,
      "covid_19_underlying_cause" => 0
    }

    with {:ok, file} <- File.read(saved_file_path),
         {:ok, json} <- Poison.decode(file) do
      sum =
        json
        |> Enum.filter(fn x ->
          x["year"] != "2021"
        end)
        |> Enum.reduce(starter, fn cv, acc ->
          Enum.map(acc, fn {k, v} ->
            {k, v + String.to_integer(cv[k])}
          end)
        end)
        |> Enum.into(%{})
        |> Poison.encode!()

      File.write(System.get_env("ANNUAL_DEATHS_BY_CAUSE_2020"), sum)
    end
  end

  @doc """
  Opens the cases and deaths by age group files, combines the data, and writes the combined data to a new, single file.
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
  Takes the case and death by age data and returns a list of maps of the combined data.
  """
  def get_combined_age_data(cases_data, deaths_data) do
    cases_keys = Enum.map(cases_data, fn x -> x["age_group"] end)
    deaths_keys = Enum.map(deaths_data, fn x -> x["age_group"] end)

    combined_data =
      Enum.concat(cases_keys, deaths_keys)
      |> Enum.uniq()
      |> Enum.reduce([], fn age_group, acc ->
        %{"age_group" => _death_age_group, "count" => deaths} =
          Enum.find(deaths_data, fn d -> d["age_group"] == age_group end)

        %{"age_group" => _cases_age_group, "count" => cases} =
          Enum.find(cases_data, fn d -> d["age_group"] == age_group end)

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
  Converts CSV of daily cases from CDC provisional data (https://covid.cdc.gov/covid-data-tracker/#trends_dailytrendscases)
  to JSON of monthly cases.
  """
  def get_daily_cases_output() do
    get_daily_output(
      System.get_env("DAILY_CASES_CSV"),
      [:state, :date, :new_cases, :seven_day_moving_average, :historic_cases],
      System.get_env("DAILY_CASES_OUTPUT")
    )
  end

  @doc """
  Converts CSV of daily deaths from CDC provisional data (https://covid.cdc.gov/covid-data-tracker/#trends_dailytrendscases)
  to JSON of monthly deaths.
  """
  def get_daily_deaths_output() do
    get_daily_output(
      System.get_env("DAILY_DEATHS_CSV"),
      [:state, :date, :new_deaths, :seven_day_moving_average, :historic_deaths],
      System.get_env("DAILY_DEATHS_OUTPUT")
    )
  end

  @doc """
  Takes the cases or deaths CSV, sums by month, and writes to a JSON file.
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
