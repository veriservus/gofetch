# Gofetch

A gopher protocol implementation in elixir

This is a toy implementation of RFC 1436. Things are not finished but the gopher DSL takes shape and is somewhat usable:

## A sample app:
```elixir
defmodule Gofetch.App do
  use Gofetch.Dsl
  alias Gofetch.Response, as: R
  require Logger

  r do
    "/home" -> home()
    "/home/about" -> about()
  end

  def root() do
    [
      R.info("Hello to my gopher"),
      R.info("This is a test implementation of RFC 1436"),
      R.stanza(:submenu, "Home", "/home")
    ]
  end

  def home() do
    R.stanza(:submenu, "About", "/home/about")
  end

  def about() do
    [
      R.info("About my home:"),
      R.info("Some info about my home"),
    ]
  end
end
```

