defmodule VerbNet do
  @moduledoc """
  Documentation for VerbNet.
  """

  # Some handy module attributes for locating assets.
  @external_resource verbnet_xml_path = Path.join([__DIR__, "..", "assets", "verbnet"])

  # Load and parse each VerbNet class XML.
  for fname <- Path.wildcard(Path.join([verbnet_xml_path, "*.xml"])) do
    # Note that we're not error-trapping.
    # If the VerbNet XML fails to parse, we treat that as a compile error.
    {:ok, vn_class, _rest} = File.read!(fname) |> :erlsom.simple_form()
    vn_class
    |> VerbNet.Compile.simpleform_to_map()
    |> IO.inspect()

    # Now start tearing apart the parsed XML to generate our functions.
  end
end
