defmodule Fetch do
  @moduledoc """
  Fetch contains helper methods for fetching API data.
  """

  @doc """
  Takes 1) an HTTPoison response and 2) a file path and name and writes the to
  the file path, if successful.
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
end
