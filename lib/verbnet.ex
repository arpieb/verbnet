defmodule VerbNet do
  @moduledoc """
  Documentation for VerbNet.
  """

  # Some handy module attributes for locating assets.
  @external_resource verbnet_xml_path = Path.join([__DIR__, "..", "assets", "verbnet"])

  # Load and parse each VerbNet class XML.
  #for fname <- Enum.take(Path.wildcard(Path.join([verbnet_xml_path, "*.xml"])), 1) do
  for fname <- Path.wildcard(Path.join([verbnet_xml_path, "*.xml"])) do
    # Note that we're not error-trapping.
    # If the VerbNet XML fails to parse, we treat that as a compile error.
    {:ok, vn_class, _rest} = File.read!(fname) |> :erlsom.simple_form()

    # Postprocess the erlsom tuple into values we can unquote.
    {:vnclass, %{id: class_id}, classdef} = VerbNet.XML.simpleform_to_map(vn_class)
    classdef_esc = Macro.escape(classdef)

    sections = VerbNet.XML.extract_sections(classdef)
    members_esc = sections |> Map.get(:members, %{}) |> Macro.escape()
    roles_esc = sections |> Map.get(:themroles, %{}) |> Macro.escape()
    frames_esc = sections |> Map.get(:frames, %{}) |> Macro.escape()

    # Define lookup functions for this VerbNet class.
    def class(unquote(class_id)), do: unquote(classdef_esc)
    def members(unquote(class_id)), do: unquote(members_esc)
    def roles(unquote(class_id)), do: unquote(roles_esc)
    def frames(unquote(class_id)), do: unquote(frames_esc)
  end

  @doc ~S"""
  Return complete map of the entire VerbNet class.

  On failed lookup, returns :invalid_class.
  """
  @spec class(class_id :: binary) :: map
  def class(_class_id) do
    :invalid_class
  end

  @doc ~S"""
  Return list of member maps for VerbNet class, keyed by member name.

  On failed lookup, returns :invalid_class.
  """
  @spec members(class_id :: binary) :: map
  def members(_class_id) do
    :invalid_class
  end

  @doc ~S"""
  Return list of thematic role maps for VerbNet class, keyed by role type.

  On failed lookup, returns :invalid_class.
  """
  @spec roles(class_id :: binary) :: map
  def roles(_class_id) do
    :invalid_class
  end

  @doc ~S"""
  Return list of semantic frames for VerbNet class, keyed by primary POS pattern.

  On failed lookup, returns :invalid_class.
  """
  @spec frames(class_id :: binary) :: list
  def frames(_class_id) do
    :invalid_class
  end

end
