defmodule HealbaneWeb.ErrorJSONTest do
  use HealbaneWeb.ConnCase, async: true

  test "renders 404" do
    assert HealbaneWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert HealbaneWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
