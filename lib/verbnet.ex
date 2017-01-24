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
    {:vnclass, %{id: class_id}, classdef} = VerbNet.Compile.simpleform_to_map(vn_class)
    classdef_esc = Macro.escape(classdef)

    sections = VerbNet.Compile.extract_sections(classdef)
    members_esc = sections |> Map.get(:members, %{}) |> Macro.escape()

    # Define lookup functions for this VerbNet class.
    def class(unquote(class_id)), do: unquote(classdef_esc)
    def members(unquote(class_id)), do: unquote(members_esc)
  end

  def class(_) do
    []
  end

  def members(_) do
    []
  end

end
