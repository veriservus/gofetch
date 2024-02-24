defmodule GofetchTest do
  use ExUnit.Case
  doctest Gofetch

  test "greets the world" do
    assert Gofetch.hello() == :world
  end
end
