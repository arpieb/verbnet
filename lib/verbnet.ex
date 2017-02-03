defmodule VerbNet do
  @moduledoc ~S"""
  This module provides a lookup interface into the [VerbNet](https://verbs.colorado.edu/~mpalmer/projects/verbnet.html)
  semantic mapping dataset.
  """

  # Some handy module attributes for locating assets.
  @external_resource verbnet_xml_path = Path.join([__DIR__, "..", "assets", "verbnet"])

  # Start timer
  start = System.monotonic_time()

  # Load and parse each VerbNet class XML.
  Code.ensure_compiled(VerbNet.XML)
  classes = Path.join([verbnet_xml_path, "*.xml"])
  |> Path.wildcard()
  |> Task.async_stream(VerbNet.XML, :process_xml, [])
  |> Enum.to_list()
  |> Enum.map(fn({:ok, class_list}) -> class_list end)
  |> List.flatten()

  # Process each class extracted from the XML, generate basic class info lookups and collect all frame-member mappings.
  all_frames = for {class_id, classdef, sections} <- classes do
    # Extract the sections into values we can unquote.
    members = sections |> Map.get(:members, %{})
    roles = sections |> Map.get(:themroles, %{})
    frames = sections |> Map.get(:frames, %{})

    # Define basic lookup functions for this VerbNet class.
    def class(unquote(class_id)), do: unquote(Macro.escape(classdef))
    def members(unquote(class_id)), do: unquote(Macro.escape(members))
    def roles(unquote(class_id)), do: unquote(Macro.escape(roles))
    def frames(unquote(class_id)), do: unquote(Macro.escape(frames))

    # Aggregate frame-member mappings for return.
    for {primary, frame} <- frames, member <- members |> Map.keys() do
      {primary, member, Map.put(frame, :class_id, class_id)}
    end
  end
  |> List.flatten()
  |> Enum.reduce(%{}, fn({primary, member, frame}, acc) -> Map.update(acc, {primary, member}, [frame], fn(frames) -> [frame] ++ frames end) end)

  # Now generate frame-member lookups.
  for {{primary, member}, frames} <- all_frames do
    def find_frame(unquote(primary), unquote(member)), do: unquote(Macro.escape(frames))
  end

  # End timer
  elapsed = (System.monotonic_time() - start) |> System.convert_time_unit(:native, :millisecond)
  IO.puts "Codified #{Enum.count(classes)} VerbNet classes in #{elapsed}ms"

  @doc ~S"""
  Return complete raw map of the entire VerbNet class.

  On failed lookup, returns :invalid_class.
  """
  @spec class(class_id :: binary) :: map
  def class(class_id) do
    invalid_class(class_id)
  end

  @doc ~S"""
  Return list of member maps for VerbNet class, keyed by member name.

  On failed lookup, returns :invalid_class.

  ## Examples

      iex> VerbNet.members("wish-62")
      %{"aim" => %{grouping: "aim.02", wn: "aim%2:31:01"},
        "dream" => %{grouping: "dream.01", wn: "dream%2:36:00"},
        "expect" => %{grouping: "expect.01", wn: "expect%2:32:00"},
        "imagine" => %{grouping: "imagine.02", wn: "imagine%2:31:01"},
        "intend" => %{grouping: "intend.01", wn: "intend%2:31:00"},
        "mean" => %{grouping: "mean.02", wn: "mean%2:31:00"},
        "plan" => %{grouping: "plan.01", wn: "plan%2:31:01"},
        "propose" => %{grouping: "propose.02", wn: "propose%2:31:01"},
        "think" => %{grouping: "think.05", wn: "think%2:31:03"},
        "wish" => %{grouping: "wish.02", wn: "wish%2:37:02"},
        "yen" => %{grouping: "", wn: "yen%2:37:00"}}

      iex> VerbNet.members("foo")
      :invalid_class

  """
  @spec members(class_id :: binary) :: map
  def members(class_id) do
    invalid_class(class_id)
  end

  @doc ~S"""
  Return list of thematic role maps for VerbNet class, keyed by role type.

  On failed lookup, returns :invalid_class.

  ## Examples

      iex> VerbNet.roles("wish-62")
      %{"Experiencer" => [{:selrestrs, %{logic: "or"},
          [{:selrestr, %{type: "animate", value: "+"}, []},
           {:selrestr, %{type: "organization", value: "+"}, []}]}],
        "Stimulus" => [{:selrestrs, %{}, []}]}

      iex> VerbNet.roles("foo")
      :invalid_class

  """
  @spec roles(class_id :: binary) :: map
  def roles(class_id) do
    invalid_class(class_id)
  end

  @doc ~S"""
  Return list of semantic frames for VerbNet class, keyed by primary POS pattern.

  On failed lookup, returns :invalid_class.

  ## Examples

      iex> VerbNet.frames("wish-62") |> Map.keys()
      ["NP V NP", "NP V NP ADJ", "NP V NP to be ADJ", "NP V S_INF",
       "NP V for NP S_INF", "NP V that S"]

      iex> VerbNet.frames("foo")
      :invalid_class

  """
  @spec frames(class_id :: binary) :: list
  def frames(class_id) do
    invalid_class(class_id)
  end

  @doc ~S"""
  Return semantic frame from VerbNet that matches the provided primary POS pattern and class member.

  On failed lookup, returns :no_match.

  ## Examples

      iex> VerbNet.find_frame("NP V NP", "wish")
      %{class_id: "wish-62",
        description: %{descriptionnumber: "8.1", primary: "NP V NP", secondary: "NP",
          xtag: "0.2"}, examples: [["I wished it."]],
        semantics: [{:pred, %{value: "desire"},
          [{:args, %{},
            [{:arg, %{type: "Event", value: "E"}, []},
             {:arg, %{type: "ThemRole", value: "Experiencer"}, []},
             {:arg, %{type: "ThemRole", value: "Stimulus"}, []}]}]}],
        syntax: [{:np, %{value: "Experiencer"}, [{:synrestrs, %{}, []}]},
         {:verb, %{}, []},
         {:np, %{value: "Stimulus"},
          [{:synrestrs, %{}, [{:synrestr, %{type: "sentential", value: "-"}, []}]}]}]}

      iex> VerbNet.find_frame(["NP", "V", "NP"], "wish")
      %{class_id: "wish-62",
        description: %{descriptionnumber: "8.1", primary: "NP V NP", secondary: "NP",
          xtag: "0.2"}, examples: [["I wished it."]],
        semantics: [{:pred, %{value: "desire"},
          [{:args, %{},
            [{:arg, %{type: "Event", value: "E"}, []},
             {:arg, %{type: "ThemRole", value: "Experiencer"}, []},
             {:arg, %{type: "ThemRole", value: "Stimulus"}, []}]}]}],
        syntax: [{:np, %{value: "Experiencer"}, [{:synrestrs, %{}, []}]},
         {:verb, %{}, []},
         {:np, %{value: "Stimulus"},
          [{:synrestrs, %{}, [{:synrestr, %{type: "sentential", value: "-"}, []}]}]}]}

      iex> VerbNet.find_frame("NP V NP", "foo")
      :no_match

  """
  @spec find_frame(primary :: binary, member :: binary) :: map
  def find_frame(primary, member) when is_binary(primary) do
    no_match(primary, member)
  end

  @spec find_frame(primary :: list, member :: binary) :: map
  def find_frame(primary, member) when is_list(primary) do
    find_frame(Enum.join(primary, " "), member)
  end

  # Util method to return :invalid_class, yet allow function specs to provide useful help.
  # Reason: _class_id was generating "arg1" in REPL help and docs.
  defp invalid_class(_class_id) do
    :invalid_class
  end

  # Util method to return :no_match, yet allow function specs to provide useful help.
  # Reason: _primary, _member was generating "arg1, arg2" in REPL help and docs.
  defp no_match(_primary, _member) do
    :no_match
  end

end
