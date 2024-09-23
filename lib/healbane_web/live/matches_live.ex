defmodule HealbaneWeb.MatchesLive do
  use HealbaneWeb, :live_view
  import HealbaneWeb.CommonComponents
  import HealbaneWeb.HUDComponents
  alias Healbane.WatchServer
  alias HealbaneWeb.MatchLive

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(:timer.seconds(1), self(), :tick)
    end

    replays =
      Path.wildcard("./defs/replays/*.meta")
      |> Enum.map(fn path ->
        f = File.read!(path)
        {:ok, match_meta} = Healbane.decode_meta(f)
        {:ok, match_details} = Healbane.decode_match_details(match_meta.match_details)
        match_details
      end)

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

    socket =
      socket
      |> assign(page_title: "Home")
      |> assign(heroes: heroes)
      |> assign(heroes_by_id: heroes_by_id)
      |> assign(i18n: i18n)
      |> assign(replays: replays)

    {current_match_id, duration_s, current_s} = WatchServer.get_current_replay()

    {:ok,
     assign(socket,
       current_match_id: current_match_id,
       duration_s: duration_s,
       current_s: current_s
     )}
  end

  def handle_info(:tick, socket) do
    {current_match_id, duration_s, current_s} = WatchServer.get_current_replay()

    {:noreply,
     assign(socket,
       current_match_id: current_match_id,
       duration_s: duration_s,
       current_s: current_s
     )}
  end
end
