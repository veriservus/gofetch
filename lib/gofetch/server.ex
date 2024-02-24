defmodule Gofetch.Server do
  alias Gofetch.Response, as: R
  use GenServer
  require Logger

  defstruct(active_conns: [])

  @type t :: %__MODULE__{active_conns: list(port)}

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  def init(port) do
    case do_listen(port) do
      {true, listen_socket} ->
        Task.start_link(fn -> loop_acceptor(listen_socket) end)

      {false, errno} ->
        Logger.error(inspect(errno))
    end

    {:ok, %__MODULE__{}}
  end

  def handle_cast({:add_conn, client_socket}, state) do
    {:noreply,
     %{state | active_conns: state.active_conns ++ [client_socket]}}
  end

  def handle_cast({:remove_conn, client_socket}, state) do
    {:noreply, %{state | active_conns: state.active_conns -- [client_socket]}}
  end

  defp do_listen(port) do
    case :gen_tcp.listen(port, packet: 0, active: false) do
      {:ok, listen_socket} ->
        {true, listen_socket}

      {:error, errno} ->
        {false, errno}
    end
  end

  defp loop_acceptor(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        add_conns(client_socket)

        spawn(fn ->
          do_recv(client_socket, 0)
        end)

        ## :sys.get_state(__MODULE__)
        loop_acceptor(listen_socket)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  defp do_recv(client_socket, length) do
    case :gen_tcp.recv(client_socket, length) do
      {:ok, data} ->
        data_handler(client_socket, data)

      {:error, :closed} ->
        Logger.info("client closed")

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  defp data_handler(client_socket, data) do
    data_s = data |> to_string() |> String.trim()
    Logger.info("Request: #{data_s}")
    cond do
      data_s |> String.equivalent?("bye") ->
        do_close(client_socket)

      true ->
        do_gopher(client_socket, data_s)
    end
  end

  defp do_gopher(client_socket, request) do
    page = case request do
      "/home" -> gopher_home()
      "/home/about" -> gopher_about()
      "" -> gopher_root()
      other -> gopher_error(other)
    end

    Logger.info("Sending: #{inspect(page)}")

    send_page(client_socket, page)
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

  def send_page(client_socket, page) when is_binary(page) do
    send_page(client_socket, [page])
  end

  def send_page(client_socket, page) when is_list(page) do
    do_send(client_socket, Enum.join(page ++ [".\n"], "\n"))
  end

  defp do_send(client_socket, data) do
    Logger.info("Sending: #{inspect(data)}")
    case :gen_tcp.send(client_socket, data) do
      :ok ->
        do_recv(client_socket, 0)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  def show_conns_info() do
    :sys.get_state(__MODULE__)
    |> Map.get(:active_conns)
    |> Enum.map(fn port -> :inet.peername(port) |> elem(1) end)
  end

  defp do_close(client_socket) do
    :gen_tcp.close(client_socket)
    remove_conns(client_socket)
  end

  def close_conns() do
    :sys.get_state(__MODULE__)
    |> Map.get(:active_conns)
    |> Enum.each(fn conn -> do_close(conn) end)
  end

  # clinetAPI

  def add_conns(client_socket) do
    GenServer.cast(__MODULE__, {:add_conn, client_socket})
  end

  def remove_conns(client_socket) do
    GenServer.cast(__MODULE__, {:remove_conn, client_socket})
  end
end
