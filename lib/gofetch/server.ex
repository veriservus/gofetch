defmodule Gofetch.Server do
  use GenServer
  require Logger

  defstruct [
    :app,
    :active_conns,
  ]

  @type t :: %__MODULE__{
    app: module(),
    active_conns: list(port)
  }

  def start_link(app_module, port) do
    GenServer.start_link(__MODULE__, {app_module, port}, name: __MODULE__)
  end

  def init({app, port}) do
    case do_listen(port) do
      {true, listen_socket} ->
        Task.start_link(fn -> loop_acceptor(listen_socket, app) end)

      {false, errno} ->
        Logger.error(inspect(errno))
    end

    {:ok, %__MODULE__{app: app, active_conns: []}}
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

  defp loop_acceptor(listen_socket, app) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        add_conns(client_socket)

        spawn(fn ->
          do_recv(app, client_socket, 0)
        end)

        ## :sys.get_state(__MODULE__)
        loop_acceptor(listen_socket, app)

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  defp do_recv(app, client_socket, length) do
    case :gen_tcp.recv(client_socket, length) do
      {:ok, data} ->
        data_handler(client_socket, app, data)

      {:error, :closed} ->
        Logger.info("client closed")

      {:error, errno} ->
        Logger.error(errno)
    end
  end

  defp data_handler(client_socket, app, data) do
    data_s = data |> to_string() |> String.trim()
    Logger.info("Request: #{data_s}")
    cond do
      data_s |> String.equivalent?("bye") ->
        do_close(client_socket)

      true ->
        do_gopher(client_socket, app, data_s)
    end
  end

  defp do_gopher(client_socket, app, request) do
    page = apply(app, :routes, [request])

    Logger.info("Sending: #{inspect(page)}")

    send_page(client_socket, app, page)
  end

  def send_page(client_socket, app, page) when is_binary(page) do
    send_page(client_socket, app, [page])
  end

  def send_page(client_socket, app, page) when is_list(page) do
    do_send(client_socket, app, Enum.join(page ++ [".\n"], "\n"))
  end

  defp do_send(client_socket, app, data) do
    Logger.info("Sending: #{inspect(data)}")
    case :gen_tcp.send(client_socket, data) do
      :ok ->
        do_recv(app, client_socket, 0)

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
