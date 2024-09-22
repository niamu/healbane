defmodule HealbaneWeb.MatchesLive do
  use HealbaneWeb, :live_view
  alias Healbane.WatchServer

  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(:timer.seconds(30), self(), :tick)
    end

    replays =
      Path.wildcard("./defs/replays/*.meta")
      |> Enum.map(&(&1 |> Path.basename() |> Path.rootname() |> Integer.parse() |> elem(0)))

    socket =
      socket
      |> assign(page_title: "Home")
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
