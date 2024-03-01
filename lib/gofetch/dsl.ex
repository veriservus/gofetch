defmodule Gofetch.Dsl do
  alias Gofetch.Response, as: R

  defmacro __using__(_opts) do
    quote do
      import Gofetch.Dsl
    end
  end

  defmacro r([do: clauses]) do
    rest_of_clauses = quote do
       "" -> root()
       other -> error(other)
    end

    quote do
      def routes(request) do
        case request, unquote([do: clauses ++ rest_of_clauses])
      end
    end
  end

  def error(matched) do
    R.does_not_exist(matched)
  end
end
