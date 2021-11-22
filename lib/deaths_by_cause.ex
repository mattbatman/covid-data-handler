defmodule DeathsByCause do
  @moduledoc """
  DeathsByCause handles interactions with the CDC's API dataset called,
  ["Monthly Provisional Counts of Deaths by Select Causes, 2020-2021"](https://data.cdc.gov/NCHS/Monthly-Provisional-Counts-of-Deaths-by-Select-Cau/9dzk-mvmi
  """

  @doc """
  Calculates the 2020 annual deaths by select causes from saved monthly
  2020 and 2021 deaths by select causes.

  The monthly data should be fetched first, and specified in the
  MONTHLY_DEATHS_BY_CAUSE_20_21_RAW environment variable. Output is to the
  ANNUAL_DEATHS_BY_CAUSE_2020 environment variable.

  Sample output:
  {
    "symptoms_signs_and_abnormal":34296,
    "septicemia":40125,
    "other_diseases_of_respiratory":45177,
    "nephritis_nephrotic_syndrome":52600,
    "natural_cause":3104532,
    "motor_vehicle_accidents":42630,
    "malignant_neoplasms":603092,
    "intentional_self_harm_suicide":46100,
    "influenza_and_pneumonia":53665,
    "drug_overdose":92450,
    "diseases_of_heart":698151,
    "diabetes_mellitus":102295,
    "covid_19_underlying_cause":351508,
    "covid_19_multiple_cause_of":385267,
    "chronic_lower_respiratory":152771,
    "cerebrovascular_diseases":160516,
    "assault_homicide":24691,
    "alzheimer_disease":134281,
    "all_cause":3390025,
    "accidents_unintentional":202393
  }
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
  Fetches monthly counts of death and saves to the JSON file specified in the
  MONTHY_DEATHS_BY_CAUSE_20_21_RAW environment variable.

  Sample output:
  [
    {
      "data_as_of":"2021-09-15T00:00:00.000",
      "start_date":"2020-01-01T00:00:00.000",
      "end_date":"2020-01-31T00:00:00.000",
      "jurisdiction_of_occurrence":"United States",
      "year":"2020",
      "month":"1",
      "all_cause":"264680",
      "natural_cause":"242914",
      "septicemia":"3687",
      "malignant_neoplasms":"52631",
      "diabetes_mellitus":"8235",
      "alzheimer_disease":"11122",
      "influenza_and_pneumonia":"6655",
      "chronic_lower_respiratory":"15534",
      "other_diseases_of_respiratory":"4497",
      "nephritis_nephrotic_syndrome":"4886",
      "symptoms_signs_and_abnormal":"2770",
      "diseases_of_heart":"60892",
      "cerebrovascular_diseases":"14112",
      "accidents_unintentional":"15009",
      "motor_vehicle_accidents":"2916",
      "intentional_self_harm_suicide":"4039",
      "assault_homicide":"1710",
      "drug_overdose":"6542",
      "covid_19_multiple_cause_of":"5",
      "covid_19_underlying_cause":"3"
    },
    ...
  ]
  """
  def save_monthly_deaths_by_cause_2020_2021() do
    fetch_monthly_deaths_by_cause_2020_2021()
    |> Fetch.handle_fetch(System.get_env("MONTHLY_DEATHS_BY_CAUSE_20_21_RAW"))
  end

  @doc """
  Calls the CDC API for the dataset. An app token registered with the CDC API is
  required to use this function.
  """
  def fetch_monthly_deaths_by_cause_2020_2021() do
    HTTPoison.get("https://data.cdc.gov/resource/9dzk-mvmi.json",
      "X-App-Token": System.get_env("CDC_APP_TOKEN"),
      "content-type": "application/json"
    )
  end
end
