defmodule HealbaneWeb.PageController do
  use HealbaneWeb, :controller

  def home(conn, _params) do
    replays =
      Path.wildcard("./defs/replays/*.meta")
      |> Enum.map(&(&1 |> Path.basename() |> Path.rootname()))

    conn
    |> assign(:replays, replays)
    |> render(:home, layout: false)
  end

  def match(conn, %{"match_id" => match_id}) do
    f =
      case File.read("./defs/replays/#{match_id}.meta") do
        {:ok, f} -> f
        _ -> raise Phoenix.Router.NoRouteError, conn: conn, router: HealbaneWeb.Router
      end

    {:ok, match_meta} = Healbane.decode_meta(f)
    {:ok, match_details} = Healbane.decode_match_details(match_meta.match_details)

    heroes =
      File.read!("/Users/niamu/Desktop/Deadlock/exported/scripts/heroes.vdata")
      |> KeyValues3.decode!()

    heroes_by_id =
      heroes
      |> Map.delete("generic_data_type")
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc -> Map.put(acc, Map.get(v, "m_HeroID"), k) end)

    abilities =
      File.read!("/Users/niamu/Desktop/Deadlock/exported/scripts/abilities.vdata")
      |> KeyValues3.decode!()

    abilities_by_id =
      File.read!("./defs/abilities_map.json")
      |> :json.decode()
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc ->
        {k, _} = Integer.parse(k)
        Map.put(acc, k, Regex.replace(~r/(.*?)\/.*$/, v, "\\g{1}"))
      end)

    i18n =
      with {:ok, vdf} <-
             File.read!("./defs/citadel_gc_english.txt")
             |> String.trim("\uFEFF")
             |> VDF.Reader.parse_string() do
        vdf
        |> Map.get("lang")
        |> Map.get("Tokens")
      end

    players_by_team = match_details.match_info.players |> Enum.group_by(& &1.team)

    player_awards =
      match_details.match_info.players
      |> List.foldl(%{}, fn player, acc ->
        acc
        |> Map.put(:networth, Enum.max([Map.get(acc, :networth, 0), player.net_worth]))
        |> Map.put(:kills, Enum.max([Map.get(acc, :kills, 0), player.kills]))
        |> Map.put(:assists, Enum.max([Map.get(acc, :assists, 0), player.assists]))
        |> Map.put(
          :player_damage,
          Enum.max([Map.get(acc, :player_damage, 0), List.last(player.stats).player_damage])
        )
        |> Map.put(
          :objective_damage,
          Enum.max([Map.get(acc, :objective_damage, 0), List.last(player.stats).boss_damage])
        )
        |> Map.put(
          :healing,
          Enum.max([Map.get(acc, :healing, 0), List.last(player.stats).player_healing])
        )
      end)

    steamids =
      Enum.map(match_details.match_info.players, fn player ->
        player.account_id + 76_561_197_960_265_728
      end)

    api_key = Application.get_env(:healbane, :steam_api_key)
    player_summaries_endpoint = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/"
    url = "#{player_summaries_endpoint}?key=#{api_key}&steamids=#{Enum.join(steamids, ",")}"

    players_by_id =
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

    conn
    |> assign(:page_title, "Post Game #{match_id}")
    |> assign(:match_details, match_details)
    |> assign(:players_by_team, players_by_team)
    |> assign(:players_by_id, players_by_id)
    |> assign(:player_awards, player_awards)
    |> assign(:heroes, heroes)
    |> assign(:heroes_by_id, heroes_by_id)
    |> assign(:abilities, abilities)
    |> assign(:abilities_by_id, abilities_by_id)
    |> assign(:i18n, i18n)
    |> render(:match, layout: false)
  end
end
