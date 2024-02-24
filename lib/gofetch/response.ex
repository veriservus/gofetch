defmodule Gofetch.Response do
  @text "0"
  @submenu "1"
  @error "3"
  @binary "9"
  @mirror "+"
  @gif "g"
  @image "I"
  @document "d"
  @html "h"
  @png "p"
  @sound "s"
  @pdf "P"
  @xml "X"
  @info "i"

  @types %{
    text: @text,
    submenu: @submenu,
    error: @error,
    binary: @binary,
    mirror: @mirror,
    gif: @gif,
    image: @image,
    document: @document,
    html: @html,
    png: @png,
    sound: @sound,
    pdf: @pdf,
    xml: @xml,
    info: @info
  }

  @default_port "8080"

  @spec stanza(any(), any(), any(), any(), any()) :: <<_::32, _::_*8>>
  def stanza(item_type, display, selector, host \\ "localhost", port \\ @default_port) when is_map_key(@types, item_type) do
    "#{@types[item_type]}#{display}\t#{selector}\t#{host}\t#{port}"
  end

  def info(txt) do
    stanza(:info, txt, "fake", "(NULL)", "0")
  end

  def does_not_exist(what) do
    stanza(:error, "'#{what}' does not exist", "(handler not found)", "error.host", "1")
  end
end
