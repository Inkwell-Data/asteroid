defmodule Asteroid.OAuth2.RedirectUri do
  @moduledoc """
  Helper functions to deal with redirect URIs
  """

  @type t :: String.t()

  @doc """
  Returns `true` if a redirect uri is valid, `false` otherwise
  """

  @spec valid?(String.t()) :: boolean()

  def valid?(redirect_uri) when is_binary(redirect_uri) do
    parsed_uri = URI.parse(redirect_uri)

    if parsed_uri.scheme != nil and parsed_uri.fragment == nil do
      true
    else
      false
    end
  end

  def valid?(_) do
    false
  end
end
