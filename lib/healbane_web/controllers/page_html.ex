defmodule HealbaneWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HealbaneWeb, :html

  import HealbaneWeb.CommonComponents
  import HealbaneWeb.PostGameComponents

  embed_templates "page_html/*"
end
