defmodule Gofetch.App do
  alias Gofetch.Response, as: R
  require Logger
  def routes(request) do
    case request do
      "/home" -> gopher_home()
      "/home/about" -> gopher_about()
      "" -> gopher_root()
      other -> gopher_error(other)
    end
  end

  def gopher_root() do
    [
      R.info("Hello to my gopher"),
      R.info("This is a test implementation of RFC 1436"),
      R.stanza(:submenu, "Home", "/home")
    ]
  end

  def gopher_home() do
    R.stanza(:submenu, "About", "/home/about")
  end

  def gopher_about() do
    [
      R.info("About my home:"),
      R.info("Some info about my home"),
    ]
  end

  def gopher_error(matched) do
    R.does_not_exist(matched)
  end

end
