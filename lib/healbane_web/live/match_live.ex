defmodule HealbaneWeb.MatchLive do
  use HealbaneWeb, :live_view

  import HealbaneWeb.CommonComponents
  import HealbaneWeb.HUDComponents

  alias Healbane.Steam
  alias Healbane.WatchServer

  defp map_positions(match_details, old_map_pos_by_player_slot, current_s) do
    t = min(current_s, match_details.match_info.duration_s - 1)

    minimap_extents = %{
      x_min: -8960,
      y_min: -11520,
      x_max: 8960,
      y_max: 11520
    }

    List.foldl(match_details.match_info.match_paths.paths, %{}, fn path, acc ->
      idx = floor(length(path.x_pos) * (t / match_details.match_info.duration_s))
      x = (path.x_pos |> Enum.at(idx)) / match_details.match_info.match_paths.x_resolution
      y = (path.y_pos |> Enum.at(idx)) / match_details.match_info.match_paths.y_resolution
      x = x * (path.x_max - path.x_min) + path.x_min
      y = y * (path.y_max - path.y_min) + path.y_min
      x = (x - minimap_extents.x_min) / (minimap_extents.x_max - minimap_extents.x_min) * 100
      y = (y - minimap_extents.y_min) / (minimap_extents.y_max - minimap_extents.y_min) * 100
      health = path.health |> Enum.at(idx)

      %{:x => old_x, :y => old_y, :health => old_health} =
        Map.get(old_map_pos_by_player_slot, path.player_slot, %{
          x: 0,
          y: 0,
          health: 0
        })

      result =
        if health == 0 do
          %{x: old_x, y: old_y, health: health}
        else
          if old_health == 0 && idx > 0 do
            %{x: x, y: 100 - y, health: health, respawning: true}
          else
            %{x: x, y: 100 - y, health: health}
          end
        end

      Map.put(acc, path.player_slot, result)
    end)
  end

  def remaining_objectives(objectives, current_s) do
    objectives =
      objectives
      |> Enum.filter(fn objective ->
        objective.destroyed_time_s != 0 && objective.destroyed_time_s < current_s
      end)
      |> Enum.map(fn objective ->
        team =
          Atom.to_string(objective.team)
          |> String.replace("k_ECitadelLobbyTeam_", "")
          |> String.replace("Team1", "Team2")
          |> String.replace("Team0", "Team1")

        objective =
          Atom.to_string(objective.team_objective_id)
          |> String.replace("k_eCitadelTeamObjective_", "")
          |> String.replace("Lane", "")

        team <> objective
      end)

    [
      "Team1Core",
      "Team1Titan",
      "Team1Tier2_1",
      "Team1Tier2_2",
      "Team1Tier2_3",
      "Team1Tier2_4",
      "Team1Tier1_1",
      "Team1Tier1_2",
      "Team1Tier1_3",
      "Team1Tier1_4",
      "Team2Core",
      "Team2Titan",
      "Team2Tier2_1",
      "Team2Tier2_2",
      "Team2Tier2_3",
      "Team2Tier2_4",
      "Team2Tier1_1",
      "Team2Tier1_2",
      "Team2Tier1_3",
      "Team2Tier1_4"
    ] -- objectives
  end

  def mount(%{"match_id" => match_id}, _session, socket) do
    {match_id, ""} = Integer.parse(match_id)

    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    f =
      case File.read("./defs/replays/#{match_id}.meta") do
        {:ok, f} -> f
        _ -> raise "Unable to read file"
      end

    {:ok, match_meta} = Healbane.decode_meta(f)
    {:ok, match_details} = Healbane.decode_match_details(match_meta.match_details)

    heroes =
      File.read!("./defs/heroes.vdata")
      |> KeyValues3.decode!()

    heroes_by_id =
      heroes
      |> Map.delete("generic_data_type")
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc -> Map.put(acc, Map.get(v, "m_HeroID"), k) end)

    i18n =
      with {:ok, vdf} <-
             File.read!("./defs/citadel_gc_english.txt")
             |> String.trim("\uFEFF")
             |> VDF.Reader.parse_string() do
        vdf
        |> Map.get("lang")
        |> Map.get("Tokens")
      end

    mm_by_player_slot =
      List.foldl(match_details.match_info.players, %{}, fn player, acc ->
        Map.put(
          acc,
          player.player_slot,
          {
            Map.get(heroes, Map.get(heroes_by_id, player.hero_id))
            |> Map.get("m_strMinimapImage")
            |> elem(1)
            |> String.replace("file://{images}/", "/images/")
            |> String.replace_suffix(".psd", "_psd.png"),
            Map.get(i18n, Map.get(heroes_by_id, player.hero_id)),
            player.team
          }
        )
      end)

    {current_match_id, _duration_s, current_s} = WatchServer.get_current_replay()

    map_pos_by_player_slot = map_positions(match_details, %{}, current_s)
    objectives = remaining_objectives(match_details.match_info.objectives, current_s)

    steamids =
      Enum.map(match_details.match_info.players, fn player ->
        player.account_id + 76_561_197_960_265_728
      end)

    players_by_id = Steam.players_by_id(steamids)

    heroes =
      File.read!("./defs/heroes.vdata")
      |> KeyValues3.decode!()

    heroes_by_id =
      heroes
      |> Map.delete("generic_data_type")
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc -> Map.put(acc, Map.get(v, "m_HeroID"), k) end)

    i18n =
      with {:ok, vdf} <-
             File.read!("./defs/citadel_gc_english.txt")
             |> String.trim("\uFEFF")
             |> VDF.Reader.parse_string() do
        vdf
        |> Map.get("lang")
        |> Map.get("Tokens")
      end

    abilities =
      File.read!("./defs/abilities.vdata")
      |> KeyValues3.decode!()

    abilities_by_id =
      File.read!("./defs/abilities_map.json")
      |> :json.decode()
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc ->
        {k, _} = Integer.parse(k)
        Map.put(acc, k, Regex.replace(~r/(.*?)\/.*$/, v, "\\g{1}"))
      end)

    lane_paths = File.read!("./defs/mini-map/lane_paths.json")
      |> :json.decode()
      |> List.foldl([], fn lane_map, outer_acc ->
        lane_map = Map.update!(lane_map, "path_nodes", fn path_nodes ->
          List.foldl(path_nodes, [], fn [x, y, _z, x1, y1, _z1, x2, y2, _z2], acc ->
            acc ++ [[
                    x, y,
                    x + x1, y + y1,
                    x + x2, y + y2
                  ]]
          end)
          |> Enum.map(fn [x, y, x1, y1, x2, y2] -> "C #{x} #{y}, #{x1} #{y1}, #{x2} #{y2}" end)
          |> Enum.join(" ")
        end)
        outer_acc ++ [lane_map]
      end)

    objective_locations = File.read!("./defs/mini-map/objectives.json")
      |> :json.decode()

    socket =
      socket
      |> assign(:page_title, "Watch #{match_id}")
      |> assign(:match_id, match_id)
      |> assign(:match_details, match_details)
      |> assign(:players_by_id, players_by_id)
      |> assign(:heroes, heroes)
      |> assign(:heroes_by_id, heroes_by_id)
      |> assign(:i18n, i18n)
      |> assign(:abilities, abilities)
      |> assign(:abilities_by_id, abilities_by_id)
      |> assign(:mm_by_player_slot, mm_by_player_slot)
      |> assign(:map_pos_by_player_slot, map_pos_by_player_slot)
      |> assign(:objectives, objectives)
      |> assign(:duration_s, match_details.match_info.duration_s)
      |> assign(:current_s, nil)
      |> assign(:lane_paths, lane_paths)
      |> assign(:objective_locations, objective_locations)

    if current_match_id == match_id do
      {:ok,
       assign(socket,
         current_match_id: match_id,
         current_s: current_s
       )}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_info(:tick, socket) do
    match_id = Map.get(socket.assigns, :match_id)
    {current_match_id, _duration_s, current_s} = WatchServer.get_current_replay()

    match_details = socket.assigns.match_details

    map_pos_by_player_slot =
      map_positions(match_details, socket.assigns.map_pos_by_player_slot, current_s)

    objectives = remaining_objectives(match_details.match_info.objectives, current_s)

    if current_match_id == match_id do
      socket =
        socket
        |> assign(:current_s, current_s)
        |> assign(:map_pos_by_player_slot, map_pos_by_player_slot)
        |> assign(:objectives, objectives)

      {:noreply, socket}
    else
      {:noreply, redirect(socket, to: "/match/#{match_id}")}
    end
  end
end
