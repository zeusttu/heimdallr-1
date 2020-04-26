defmodule HeimdallrTest do
  use ExUnit.Case
  doctest Heimdallr

  test "greets the world" do
    assert Heimdallr.hello() == :world
  end
end
