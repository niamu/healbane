defmodule HealbaneWeb.HUDComponents do
  use Phoenix.Component
  import HealbaneWeb.CommonComponents

  attr :objectives, :list, required: true

  def objectives_map(assigns) do
    ~H"""
    <div data-id="ObjectivesMap">
      <div class="ObjectiveCtn">
        <div
          data-id="Team1Core"
          class={if Enum.member?(@objectives, "Team1Core") do "Alive " else "" end <> "Icon Team1 Core"}
        >
        </div>
        <div
          data-id="Team1Titan"
          class={if Enum.member?(@objectives, "Team1Titan") do "Alive " else "" end <> "Icon Team1 Titan"}
        >
        </div>
        <div
          data-id="Team1Tier2_1"
          class={if Enum.member?(@objectives, "Team1Tier2_1") do "Alive " else "" end <> "Icon Team1 Tier2"}
        >
        </div>
        <div
          data-id="Team1Tier2_2"
          class={if Enum.member?(@objectives, "Team1Tier2_2") do "Alive " else "" end <> "Icon Team1 Tier2"}
        >
        </div>
        <div
          data-id="Team1Tier2_3"
          class={if Enum.member?(@objectives, "Team1Tier2_3") do "Alive " else "" end <> "Icon Team1 Tier2"}
        >
        </div>
        <div
          data-id="Team1Tier2_4"
          class={if Enum.member?(@objectives, "Team1Tier2_4") do "Alive " else "" end <> "Icon Team1 Tier2"}
        >
        </div>
        <div
          data-id="Team1Tier1_1"
          class={if Enum.member?(@objectives, "Team1Tier1_1") do "Alive " else "" end <> "Icon Team1 Tier1"}
        >
        </div>
        <div
          data-id="Team1Tier1_2"
          class={if Enum.member?(@objectives, "Team1Tier1_2") do "Alive " else "" end <> "Icon Team1 Tier1"}
        >
        </div>
        <div
          data-id="Team1Tier1_3"
          class={if Enum.member?(@objectives, "Team1Tier1_3") do "Alive " else "" end <> "Icon Team1 Tier1"}
        >
        </div>
        <div
          data-id="Team1Tier1_4"
          class={if Enum.member?(@objectives, "Team1Tier1_4") do "Alive " else "" end <> "Icon Team1 Tier1"}
        >
        </div>
        <div
          data-id="Team2Core"
          class={if Enum.member?(@objectives, "Team2Core") do "Alive " else "" end <> "Icon Team2 Core"}
        >
        </div>
        <div
          data-id="Team2Titan"
          class={if Enum.member?(@objectives, "Team2Titan") do "Alive " else "" end <> "Icon Team2 Titan"}
        >
        </div>
        <div
          data-id="Team2Tier2_1"
          class={if Enum.member?(@objectives, "Team2Tier2_1") do "Alive " else "" end <> "Icon Team2 Tier2"}
        >
        </div>
        <div
          data-id="Team2Tier2_2"
          class={if Enum.member?(@objectives, "Team2Tier2_2") do "Alive " else "" end <> "Icon Team2 Tier2"}
        >
        </div>
        <div
          data-id="Team2Tier2_3"
          class={if Enum.member?(@objectives, "Team2Tier2_3") do "Alive " else "" end <> "Icon Team2 Tier2"}
        >
        </div>
        <div
          data-id="Team2Tier2_4"
          class={if Enum.member?(@objectives, "Team2Tier2_4") do "Alive " else "" end <> "Icon Team2 Tier2"}
        >
        </div>
        <div
          data-id="Team2Tier1_1"
          class={if Enum.member?(@objectives, "Team2Tier1_1") do "Alive " else "" end <> "Icon Team2 Tier1"}
        >
        </div>
        <div
          data-id="Team2Tier1_2"
          class={if Enum.member?(@objectives, "Team2Tier1_2") do "Alive " else "" end <> "Icon Team2 Tier1"}
        >
        </div>
        <div
          data-id="Team2Tier1_3"
          class={if Enum.member?(@objectives, "Team2Tier1_3") do "Alive " else "" end <> "Icon Team2 Tier1"}
        >
        </div>
        <div
          data-id="Team2Tier1_4"
          class={if Enum.member?(@objectives, "Team2Tier1_4") do "Alive " else "" end <> "Icon Team2 Tier1"}
        >
        </div>
      </div>
    </div>
    """
  end

  slot :hero_image, required: true
  attr :players_by_id, :map, required: true
  attr :abilities, :list, required: true
  attr :abilities_by_id, :map, required: true
  attr :player, CMsgMatchMetaDataContents.Players, required: true
  attr :map_pos_by_player_slot, :map, required: true
  attr :i18n, :map, required: true
  attr :heroes_by_id, :map, required: true
  attr :current_s, :integer, required: true

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

    current_stats =
      assigns.player
      |> Map.get(:stats)
      |> Enum.filter(fn stat -> stat.time_stamp_s <= assigns.current_s end)
      |> List.last(%{})

    current_items =
      assigns.player
      |> Map.get(:items)
      |> Enum.filter(fn item -> item.game_time_s <= assigns.current_s end)

    current_death =
      assigns.player
      |> Map.get(:death_details)
      |> Enum.filter(fn death ->
        death.game_time_s <= assigns.current_s &&
          assigns.current_s <= death.death_duration_s + death.game_time_s
      end)
      |> List.first()

    %{:x => _x, :y => _y, :health => current_health} =
      Map.get(assigns.map_pos_by_player_slot, assigns.player.player_slot)

    assigns =
      assigns
      |> assign(:player_account, player_account)
      |> assign(:hero_name, hero_name)
      |> assign(:current_stats, current_stats)
      |> assign(:current_items, current_items)
      |> assign(:current_health, current_health)
      |> assign(:current_death, current_death)

    ~H"""
    <div
      data-class="CitadelHudTopBarPlayer"
      class={"LaneNum#{@player.assigned_lane}" <> if(@current_health == 0, do: " Dead", else: "")}
    >
      <div data-id="PlayerDetailsContainer">
        <div data-id="HeroContents" class="HeroContents">
          <div data-id="HeroImageArea">
            <div data-class="CitadelHeroImage" data-id="HeroIcon">
              <div class="HeroContentsCoinBackground"></div>
              <%= render_slot(@hero_image) %>
              <div class="HeroContentsCoinInnerBorder"></div>
            </div>
          </div>
          <div class="HeroInnerContent">
            <div data-id="HealthBar">
              <progress data-id="HeroHealth" min="0" max="100" value={@current_health}></progress>
            </div>
            <%= if @current_health == 0 && @current_death do %>
              <div class="DeathStatus">
                <div class="RespawnContainer">
                  <span class="RespawnTimer">
                    <%= @current_death.death_duration_s - (@current_s - @current_death.game_time_s) %>
                  </span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
      <div data-id="PlayerNameNWContainer">
        <div class="PlayerInfoContainer">
          <div data-id="TotalSoulsContainer">
            <div class="SoulsBacker"></div>
            <div class="SoulsValueContainer">
              <span class="SoulsValue">
                <%= if Map.get(@current_stats, :net_worth, 0) >= 1000 do %>
                  <%= if Map.get(@current_stats, :net_worth, 0) >= 5000 do %>
                    <%= Integer.floor_div(Map.get(@current_stats, :net_worth, 0), 1000) %><span class="thousand">k</span>
                  <% else %>
                    <%= (Map.get(@current_stats, :net_worth, 0) / 1000) |> Float.round(1) %><span class="thousand">k</span>
                  <% end %>
                <% else %>
                  <%= Map.get(@current_stats, :net_worth, 0) %>
                <% end %>
              </span>
            </div>
          </div>
          <span class="PlayerName">
            <%= if @player_account do %>
              <a href={@player_account.url} title={@player_account.username}>
                <%= @player_account.username %>
              </a>
            <% else %>
              <span title={@hero_name}>[Bot] <%= @hero_name %></span>
            <% end %>
          </span>
          <div data-id="KDAContainer" class="TopBottomFlow">
            <div class="KDALabels">
              <span class="StatLabel">K</span>
              <span class="StatLabel">D</span>
              <span class="StatLabel">A</span>
            </div>
            <div class="KDAStats">
              <span class="PlayerStat kills"><%= Map.get(@current_stats, :kills, 0) %></span>
              <span class="ForwardSlash">/</span>
              <span class="PlayerStat deaths"><%= Map.get(@current_stats, :deaths, 0) %></span>
              <span class="ForwardSlash">/</span>
              <span class="PlayerStat assists"><%= Map.get(@current_stats, :assists, 0) %></span>
            </div>
            <.item_graphs
              items={@current_items}
              abilities={@abilities}
              abilities_by_id={@abilities_by_id}
            />
          </div>
        </div>
      </div>
    </div>
    """
  end
end
