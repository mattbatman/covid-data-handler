defmodule ProcessCovidData do
  @moduledoc """
  `ProcessCovidData` transforms data as needed after being fetched from the CDC API.
  """

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
end
