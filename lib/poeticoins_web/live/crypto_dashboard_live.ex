defmodule PoeticoinsWeb.CryptoDashboardLive do
  use PoeticoinsWeb, :live_view
  alias Poeticoins.Product
  import PoeticoinsWeb.ProductHelpers

  def mount(_params, _session, socket) do
    socket = assign(socket, trades: %{}, products: [], timezone: get_timezone_from_connection(socket))
    {:ok, socket}
  end

  def handle_info({:new_trade, trade}, socket) do
    send_update(PoeticoinsWeb.ProductComponent, id: trade.product, trade: trade)

    {:noreply, socket}
  end

  def handle_event("add-product", %{"product_id" => product_id} = _params, socket) do
    socket = maybe_add_product(socket, product_from_string(product_id))
    {:noreply, socket}
  end

  def handle_event("filter-products", %{"search" => search}, socket) do
    products =
      Poeticoins.available_products()
      |> Enum.filter(fn product ->
        String.downcase(product.exchange_name) =~ String.downcase(search) or
          String.downcase(product.currency_pair) =~ String.downcase(search)
      end)
    {:noreply, assign(socket, :products, products)}
  end

  def handle_event("remove-product", %{ "product-id" => product_id} = _params, socket) do
    product = product_from_string(product_id)
    socket = update(socket, :products, & List.delete(&1, product))
    {:noreply, socket}
  end

  defp product_from_string(product_id) do
    [exchange_name, currency_pair] = String.split(product_id, ":")
    Product.new(exchange_name, currency_pair)
  end

  defp add_product(socket, product) do
    Poeticoins.subscribe_to_trades(product)
    socket
    |> update(:products, & &1 ++ [product])
  end

  defp maybe_add_product(socket, product) do
    if product not in socket.assigns.products do
      socket
      |> add_product(product)
    else
      socket
    end
  end

  defp grouped_products_by_exchange_name do
    Poeticoins.available_products()
    |> Enum.group_by(& &1.exchange_name)
  end

  defp get_timezone_from_connection(socket) do
    case get_connect_params(socket) do
      %{"timezone" => tz} when not is_nil(tz) -> tz
      _ -> "UTC"
    end
  end
end
