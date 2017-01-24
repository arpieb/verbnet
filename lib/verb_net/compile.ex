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
  Convert {key, value} tuples into maps, also convert bitstrings to binaries.
  """
  def attrs_to_map(attrs) do
    Enum.reduce(attrs, %{}, fn({key, val}, acc) -> Map.put(acc, bitstring_to_atom(key), to_string(val)) end)
  end

  @doc ~S"""
  Convert elements in content lists to Elixir-friendly types (SimpleFormElement -> Map, bitstrings -> binaries).
  """
  def content_to_list(content_list) do
    for item <- content_list, into: [] do
      content_to_list_item(item)
    end
  end

  defp content_to_list_item({_tag, _attr, _content} = item) do
    simpleform_to_map(item)
  end

  defp content_to_list_item(item) do
    to_string(item)
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

  @doc ~S"""
  Extract sections for VerbNet class into a map, keyed by section.
  """
  def extract_sections(classdef) do
    classdef
    |> Enum.map(&extract_section/1)
    |> Map.new()
  end

  defp extract_section({:members, _attrs, members}) do
    new_members = Enum.map(members, fn({:member, attrs, _rest}) -> {Map.get(attrs, :name), Map.delete(attrs, :name)} end)
    {:members, Map.new(new_members)}
  end

  defp extract_section({type, _attrs, _rest}) do
    {type, %{}}
  end
end