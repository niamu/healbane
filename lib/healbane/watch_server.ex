defmodule Healbane.WatchServer do
  use GenServer

  def init(_opts) do
    replays =
      Path.wildcard("./defs/replays/*.meta")
      |> Enum.map(fn path ->
        f = File.read!(path)
        {:ok, match_meta} = Healbane.decode_meta(f)
        {:ok, match_details} = Healbane.decode_match_details(match_meta.match_details)

        %{
          match_id: match_details.match_info.match_id,
          duration_s: match_details.match_info.duration_s
        }
      end)

    state = %{
      replays: replays,
      current_replay_index: 0,
      current_s: 0
    }

    schedule_tick()

    {:ok, state}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_current_replay() do
    GenServer.call(__MODULE__, :get_current_replay)
  end

  # Internal interface

  def handle_cast({:set_coordinates, session_id, coordinates}, state) do
    Phoenix.PubSub.broadcast(
      PubSub,
      "draggable:#{session_id}",
      {:updated_coordinates, coordinates}
    )

    {:noreply, Map.put(state, session_id, coordinates)}
  end

  def handle_call(:get_current_replay, _from, state) do
    replays = Map.get(state, :replays, [])
    current_replay_index = Map.get(state, :current_replay_index, 0)
    %{match_id: match_id, duration_s: duration_s} = Enum.at(replays, current_replay_index)
    current_s = Map.get(state, :current_s, 0)
    {:reply, {match_id, duration_s, current_s}, state}
  end

  def handle_info(:tick, state) do
    replays = Map.get(state, :replays, [])
    current_replay_index = Map.get(state, :current_replay_index, 0)
    current_s = Map.get(state, :current_s, 0)
    current_duration_s = replays |> Enum.at(current_replay_index) |> Map.get(:duration_s, 0)

    state =
      if current_s >= current_duration_s do
        state
        |> Map.put(:current_s, 0)
        |> Map.put(:current_replay_index, rem(current_replay_index + 1, length(replays)))
      else
        Map.update!(state, :current_s, &(&1 + 1))
      end

    schedule_tick()

    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(__MODULE__, :tick, 1000)
  end
end
