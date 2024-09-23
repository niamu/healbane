defmodule Healbane.Steam do
  @player_summaries_endpoint "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/"

  def players_by_id(steamids) do
    api_key = Application.get_env(:healbane, :steam_api_key)
    url = "#{@player_summaries_endpoint}?key=#{api_key}&steamids=#{Enum.join(steamids, ",")}"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        Poison.decode!(body)
        |> Map.get("response")
        |> Map.get("players")
        |> List.foldl(%{}, fn player, acc ->
          acc
          |> Map.put(
            String.to_integer(Map.get(player, "steamid")),
            %{
              avatar: Map.get(player, "avatarfull"),
              username: Map.get(player, "personaname"),
              url: Map.get(player, "profileurl")
            }
          )
        end)

      {:error, %{reason: _reason}} ->
        nil
    end
  end
end
