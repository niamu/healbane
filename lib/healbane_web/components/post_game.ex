defmodule HealbaneWeb.PostGame do
  use Phoenix.Component

  def format_number(assigns) do
    ~H"""
    <%= format_number([], @number) %>
    """
  end

  def format_number(acc, n) do
    if n > 1000 do
      format_number(
        [Integer.mod(n, 1000) |> Integer.to_string() |> String.pad_leading(3, "0") | acc],
        Integer.floor_div(n, 1000)
      )
    else
      Enum.join([n | acc], ",")
    end
  end

  def timestamp(assigns) do
    ~H"""
    <%= div(@duration, 60) %>:<%= rem(@duration, 60)
    |> Integer.to_string()
    |> String.pad_leading(2, "0") %>
    """
  end

  def team(assigns) do
    team =
      case assigns.team do
        :k_ECitadelLobbyTeam_Team0 -> "The Amber Hand"
        :k_ECitadelLobbyTeam_Team1 -> "The Sapphire Flame"
        _ -> "Unknown"
      end

    assigns = assign(assigns, :team, team)

    ~H"""
    <%= @team %>
    """
  end

  def hero_name(assigns) do
    hero_key = Map.get(assigns.heroes_by_id, assigns.hero_id)
    assigns = assign(assigns, :hero, Map.get(assigns.i18n, hero_key))

    ~H"""
    <%= @hero %>
    """
  end

  def tier_value(tier) do
    case tier do
      "EModTier_1" -> 500
      "EModTier_2" -> 1250
      "EModTier_3" -> 3000
      "EModTier_4" -> 6200
      _ -> 0
    end
  end

  def item_graphs(assigns) do
    tiers_by_category =
      assigns.items
      |> Enum.filter(fn item -> item.sold_time_s == 0 end)
      |> Enum.map(fn item ->
        item_key = Map.get(assigns.abilities_by_id, item.item_id)
        Map.get(assigns.abilities, item_key)
      end)
      |> Enum.filter(fn item -> Map.get(item, "m_eAbilityType") == "EAbilityType_Item" end)
      |> Enum.group_by(fn item -> Map.get(item, "m_eItemSlotType") end)
      |> Map.to_list()
      |> List.foldl(%{}, fn {k, v}, acc ->
        Map.put(
          acc,
          k,
          Enum.map(v, fn item -> tier_value(Map.get(item, "m_iItemTier")) end)
          |> Enum.sum()
        )
      end)

    assigns = assign(assigns, :tiers_by_category, tiers_by_category)

    ~H"""
    <div data-id="ModBarGraph">
      <progress
        data-id="WeaponProgressBar"
        max={6200 * 4}
        value={Map.get(@tiers_by_category, "EItemSlotType_WeaponMod")}
      >
      </progress>
      <progress
        data-id="ArmorProgressBar"
        max={6200 * 4}
        value={Map.get(@tiers_by_category, "EItemSlotType_Armor")}
      >
      </progress>
      <progress
        data-id="TechProgressBar"
        max={6200 * 4}
        value={Map.get(@tiers_by_category, "EItemSlotType_Tech")}
      >
      </progress>
    </div>
    """
  end

  attr :i18n, :map, required: true
  attr :heroes, :map, required: true
  attr :heroes_by_id, :map, required: true
  attr :hero_id, :atom, required: true
  attr :rest, :global

  def hero_image(assigns) do
    hero_key = Map.get(assigns.heroes_by_id, assigns.hero_id)

    {"panorama", hero_image} =
      assigns.heroes
      |> Map.get(hero_key, %{})
      |> Map.get("m_strTopBarVertical")

    assigns =
      assign(
        assigns,
        :hero_image,
        hero_image
        |> String.replace("file://{images}/", "/images/")
        |> String.replace_suffix(".psd", "_psd.png")
      )

    assigns = assign(assigns, :hero_name, Map.get(assigns.i18n, hero_key))

    ~H"""
    <img {@rest} width="180" height="223" src={@hero_image} alt={@hero_name} />
    """
  end

  slot :hero_image, required: true
  slot :item_graphs, required: true
  attr :players_by_id, :map, default: %{}
  attr :player, CMsgMatchMetaDataContents.Players, required: true
  attr :player_awards, :map, required: true
  attr :i18n, :map, required: true
  attr :heroes_by_id, :map, required: true

  def player(assigns) do
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
              <!-- <img width="184" height="184" src={@player_account.avatar} alt="" /> -->
            </a>
          <% else %>
            <span title={@hero_name}><%= @hero_name %></span>
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
