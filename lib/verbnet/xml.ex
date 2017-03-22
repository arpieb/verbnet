defmodule VerbNet.XML do
  @moduledoc false

  @doc ~S"""
  Asynchronous callback to process XML file into tuple.
  """
  def process_xml(fname) do
    # Note that we're not error-trapping.
    # If the VerbNet XML fails to parse, we treat that as a compile error.
    {:ok, vn_class, _rest} = File.read!(fname) |> :erlsom.simple_form()

    # Recursively extract classes from XML data.
    simpleform_to_map(vn_class)
    |> extract_classes()
  end

  @doc ~S"""
  Recursive function to extract classes from XML.
  """
  def extract_classes({_tag, %{id: class_id}, classdef}) do
    sections = extract_sections(classdef)
    subclasses = Map.get(sections, :subclasses, [])
    |> Enum.map(&extract_classes/1)

    [{class_id, sections} | subclasses]
  end

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
  Extract sections of interest for VerbNet class into a map, keyed by section.
  """
  def extract_sections(classdef) do
    classdef
    |> Enum.map(&extract_section/1)
    |> Map.new()
  end

  # Extract the content from the SUBCLASSES section of the parsed XML.
  defp extract_section({:subclasses, _attrs, members}) do
    {:subclasses, members}
  end

  # Extract the content from the MEMBERS section of the parsed XML.
  defp extract_section({:members, _attrs, members}) do
    items = Enum.map(members, fn({:member, attrs, _rest}) -> {attrs.name, Map.delete(attrs, :name)} end)
    {:members, Map.new(items)}
  end

  # Extract the content from the THEMROLES section of the parsed XML.
  defp extract_section({:themroles, _attrs, themroles}) do
    items = Enum.map(themroles, fn({:themrole, attrs, rest}) -> {attrs.type, rest} end)
    {:themroles, Map.new(items)}
  end

  # Extract the content from the FRAMES section of the parsed XML.
  defp extract_section({:frames, _attrs, frames}) do
    items = Enum.map(frames, fn({:frame, _attrs, rest}) -> extract_frame(rest) end)
    {:frames, Map.new(items)}
  end

  # Extract DESCRIPTION from a specific FRAME section.
  defp extract_section({:description, attrs, _rest}) do
    {:description, attrs}
  end

  # Extract EXAMPLES from a specific FRAME section.
  defp extract_section({:examples, _attrs, rest}) do
    examples = for {:example, _attrs, text} <- rest, into: [] do
      Enum.take(text, 1)
    end
    {:examples, examples}
  end

  # Extract SYNTAX from a specific FRAME section.
  defp extract_section({:syntax, _attrs, rest}) do
    {:syntax, rest}
  end

  # Extract SEMANTICS from a specific FRAME section.
  defp extract_section({:semantics, _attrs, rest}) do
    {:semantics, rest}
  end

  # Catchall, produces an empty entry.
  defp extract_section({type, _attrs, _rest}) do
    {type, %{}}
  end

  # Extract a FRAME element into a tuple we can add to a map.
  defp extract_frame(frame) do
    frame = extract_sections(frame)
    {frame.description.primary, frame}
  end
end
