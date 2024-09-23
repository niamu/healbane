defmodule HealbaneWeb.PostGameComponents do
  use Phoenix.Component
  import HealbaneWeb.CommonComponents

  attr :rest, :global

  def stats_labels(assigns) do
    ~H"""
    <div data-id="StatsTypeContainer" {@rest}>
      <span class="StatsLabel Title">Player Stats</span>
      <span class="StatsLabel SoulsStatLabel">Total Souls</span>
      <span class="StatsLabel">Kills</span>
      <span class="StatsLabel">Deaths</span>
      <span class="StatsLabel">Assists</span>
      <span class="StatsLabel">Player DMG</span>
      <span class="StatsLabel">OBJ DMG</span>
      <span class="StatsLabel">Healing</span>
    </div>
    """
  end

  slot :hero_image, required: true
  slot :item_graphs, required: true
  attr :players_by_id, :map, default: %{}
  attr :player, CMsgMatchMetaDataContents.Players, required: true
  attr :player_awards, :map, required: true
  attr :i18n, :map, required: true
  attr :heroes_by_id, :map, required: true

  def player_column(assigns) do
    player_account =
      Map.get(
        assigns.players_by_id,
        assigns.player.account_id + 76_561_197_960_265_728
      )

    hero_name =
      Map.get(
        assigns.i18n,
        Map.get(assigns.heroes_by_id, assigns.player.hero_id)
      )

    assigns =
      assigns
      |> assign(:player_account, player_account)
      |> assign(:hero_name, hero_name)

    ~H"""
    <div class="PlayerSnippet">
      <%= render_slot(@hero_image) %>
      <div data-id="NameBarGraphs">
        <div data-id="PlayerName">
          <%= if @player_account do %>
            <a href={@player_account.url} title={@player_account.username}>
              <%= @player_account.username %>
            </a>
          <% else %>
            <span title={@hero_name}>[Bot] <%= @hero_name %></span>
          <% end %>
        </div>
        <%= render_slot(@item_graphs) %>
      </div>
      <div class="PlayerStatsContainer">
        <div
          data-id="Networth"
          class={
            if @player.net_worth >= Map.get(@player_awards, :networth, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerNetworth"><.format_number number={@player.net_worth} /></span>
        </div>
        <div
          data-id="Kills"
          class={
            if @player.kills >= Map.get(@player_awards, :kills, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerKills"><.format_number number={@player.kills} /></span>
        </div>
        <div data-id="Deaths">
          <span class="PlayerDeaths"><.format_number number={@player.deaths} /></span>
        </div>
        <div
          data-id="Assists"
          class={
            if @player.assists >= Map.get(@player_awards, :assists, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerAssists"><.format_number number={@player.assists} /></span>
        </div>
        <div
          data-id="PlayerDamage"
          class={
            if List.last(@player.stats).player_damage >=
                 Map.get(@player_awards, :player_damage, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerHeroDmg">
            <.format_number number={List.last(@player.stats).player_damage} />
          </span>
        </div>
        <div
          data-id="ObjDamage"
          class={
            if List.last(@player.stats).boss_damage >=
                 Map.get(@player_awards, :objective_damage, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerObjDmg">
            <.format_number number={List.last(@player.stats).boss_damage} />
          </span>
        </div>
        <div
          data-id="Healing"
          class={
            if List.last(@player.stats).player_healing >=
                 Map.get(@player_awards, :healing, 0) do
              "playerAward"
            end
          }
        >
          <span class="PlayerHealing">
            <.format_number number={List.last(@player.stats).player_healing} />
          </span>
        </div>
      </div>
    </div>
    """
  end
end
