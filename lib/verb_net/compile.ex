defmodule VerbNet.Compile do
  @moduledoc ~S"""
  Utility functions to assist in compiling VerbNet.
  """

  @doc ~S"""
  Converts an erlsom SimpleFormElement into something more Elixir friendly.
  """
  def simpleform_to_map({tag, attrs, content}) do
    {bitstring_to_atom(tag), attrs_to_map(attrs), content_to_list(content)}
  end

  @doc ~S"""
  Convert {key, value} tuples into maps, als convert bitstrings to binaries.
  """
  def attrs_to_map(attrs) do
    Enum.reduce(attrs, %{}, fn({key, val}, acc) -> Map.put(acc, bitstring_to_atom(key), to_string(val)) end)
  end

  @doc ~S"""
  Convert elements in content lists to Elixir-friendly types (SimpleFormElement -> Map, bitstrings -> binaries).
  """
  def content_to_list(content_list) do
    for item <- content_list, into: [] do
      case item do
        {tag, attr, content} ->
            simpleform_to_map(item)
        _ ->
            to_string(item)
      end
    end
  end

  @doc ~S"""
  Convert an Erlang bitstring to an Elixir atom.
  """
  def bitstring_to_atom(bitstr) do
    bitstr
    |> to_string()
    |> String.downcase()
    |> String.to_atom()
  end
end