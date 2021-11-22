defmodule Vaers do
  @moduledoc """
  Handles transforming exports from the [CDC's WONDER VAERS data](https://wonder.cdc.gov/vaers.html).
  """

  @doc """
  The VAERS reports export a .txt file. This function takes the locally saved
  .txt file specified by the VACCINE_EVENTS_BY_YEAR_INPUT environment variable,
  transforms the data, and saves to a JSON output specified by the VACCINE_EVENTS_BY_YEAR_OUTPUT
  environment variable.

  Before running this method, manually delete all footnotes from the .txt input.
  Leave just the last row of data.

  A sample output:
  [
    {
      "year_reported_code":"1988",
      "year_reported":"1988",
      "percent":"0.00%",
      "events_reported":"1",
      "event_category_code":"DTH",
      "event_category":"Death"
    },
    ...
  ]
  """
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
end
