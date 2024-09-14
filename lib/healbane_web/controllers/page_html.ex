defmodule HealbaneWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use HealbaneWeb, :html

  import HealbaneWeb.PostGame

  embed_templates "page_html/*"
end
