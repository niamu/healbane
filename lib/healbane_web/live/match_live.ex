defmodule HealbaneWeb.MatchLive do
  use Phoenix.LiveView

  import HealbaneWeb.PostGame

  alias Healbane.WatchServer

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
      File.read!("/Users/niamu/Desktop/Deadlock/exported/scripts/heroes.vdata")
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

    {current_match_id, duration_s, current_s} = WatchServer.get_current_replay()

    t = min(current_s, match_details.match_info.duration_s - 1)

    minimap_extents = %{
      x_min: -8960,
      y_min: -8832,
      x_max: 8960,
      y_max: 8832
    }

    map_pos_by_player_slot =
      List.foldl(match_details.match_info.match_paths.paths, %{}, fn path, acc ->
        idx = floor(length(path.x_pos) * (t / match_details.match_info.duration_s))
        x = (path.x_pos |> Enum.at(idx)) / match_details.match_info.match_paths.x_resolution
        y = (path.y_pos |> Enum.at(idx)) / match_details.match_info.match_paths.y_resolution
        x = x * (path.x_max - path.x_min) + path.x_min
        y = y * (path.y_max - path.y_min) + path.y_min
        x = (x - minimap_extents.x_min) / (minimap_extents.x_max - minimap_extents.x_min)
        y = (y - minimap_extents.y_min) / (minimap_extents.y_max - minimap_extents.y_min)
        health = path.health |> Enum.at(idx)
        Map.put(acc, path.player_slot, %{x: x * 100, y: y * 100, health: health})
      end)

    objectives =
      match_details.match_info.objectives
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

    objectives =
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

    socket =
      socket
      |> assign(:page_title, "Watch #{match_id}")
      |> assign(:match_id, match_id)
      |> assign(:match_details, match_details)
      |> assign(:mm_by_player_slot, mm_by_player_slot)
      |> assign(:map_pos_by_player_slot, map_pos_by_player_slot)
      |> assign(:objectives, objectives)
      |> assign(:current_match_id, nil)
      |> assign(:duration_s, nil)
      |> assign(:current_s, nil)

    if current_match_id == match_id do
      {:ok,
       assign(socket,
         current_match_id: current_match_id,
         duration_s: duration_s,
         current_s: current_s
       )}
    else
      {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_info(:tick, socket) do
    match_id = Map.get(socket.assigns, :match_id)
    {current_match_id, duration_s, current_s} = WatchServer.get_current_replay()

    match_details = socket.assigns.match_details

    t = min(current_s, match_details.match_info.duration_s - 1)

    minimap_extents = %{
      x_min: -8960,
      y_min: -8832,
      x_max: 8960,
      y_max: 8832
    }

    map_pos_by_player_slot =
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
          Map.get(socket.assigns.map_pos_by_player_slot, path.player_slot, %{
            x: 0,
            y: 0,
            health: 0
          })

        result =
          if health == 0 do
            %{x: old_x, y: old_y, health: health}
          else
            if old_health == 0 do
              %{x: x, y: y, health: health, respawning: true}
            else
              %{x: x, y: y, health: health}
            end
          end

        Map.put(acc, path.player_slot, result)
      end)

    objectives =
      match_details.match_info.objectives
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

    objectives =
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

    if current_match_id == match_id do
      socket =
        socket
        |> assign(:current_match_id, current_match_id)
        |> assign(:duration_s, duration_s)
        |> assign(:current_s, current_s)
        |> assign(:map_pos_by_player_slot, map_pos_by_player_slot)
        |> assign(:objectives, objectives)

      {:noreply, socket}
    else
      {:noreply, redirect(socket, to: "/match/#{match_id}")}
    end
  end
end
