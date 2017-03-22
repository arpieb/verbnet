defmodule VerbNet do
  @moduledoc ~S"""
  This module provides a lookup interface into the [VerbNet](https://verbs.colorado.edu/~mpalmer/projects/verbnet.html)
  semantic mapping dataset.
  """

  # Some handy module attributes for locating assets.
  @external_resource verbnet_xml_path = Path.join([__DIR__, "..", "assets", "verbnet"])

  # Start timer
  IO.puts("Compiling VerbNet XML to static lookups takes a while...")
  start = System.monotonic_time()

  # Load and parse each VerbNet class XML.
  Code.ensure_compiled(VerbNet.XML)
  classes = Path.join([verbnet_xml_path, "*.xml"])
  |> Path.wildcard()
  |> Task.async_stream(VerbNet.XML, :process_xml, [], timeout: 60_000)
  |> Enum.to_list()
  |> Enum.map(fn({:ok, class_list}) -> class_list end)
  |> List.flatten()

  # Process each class extracted from the XML, generate basic class info lookups and collect all frame-member mappings.
  IO.puts("Processing #{Enum.count(classes)} parsed VerbNet classes")
  all_frames = for {class_id, sections} <- classes do
    # Define basic lookup functions for this VerbNet class.
    def class(unquote(class_id)), do: unquote(Macro.escape(sections))

    # Aggregate frame-member mappings for return.
    members = sections |> Map.get(:members, %{})
    frames = sections |> Map.get(:frames, %{})
    for {primary, _frame} <- frames, member <- members |> Map.keys() do
      {primary, member, class_id}
    end
  end
  |> List.flatten()
  |> Enum.reduce(%{}, fn({primary, member, class_id}, acc) -> Map.update(acc, {primary, member}, [class_id], fn(class_ids) -> [class_id] ++ class_ids end) end)

  # Now generate our function heads for frame lookups
  IO.puts("Processing #{Enum.count(all_frames)} VerbNet frames")

  def find_frames(primary, member) when is_binary(primary) do
    Map.get(unquote(Macro.escape(all_frames)), {primary, member}, []) |> aggregate_class_frames(primary)
  end

  # End timer
  elapsed = (System.monotonic_time() - start) |> System.convert_time_unit(:native, :millisecond)
  IO.puts("Codified VerbNet classes in #{elapsed}ms")

  @doc ~S"""
  Return semantic frame from VerbNet that matches the provided primary POS pattern and class member.

  On failed lookup, returns an empty list.

  ## Examples

      iex> VerbNet.find_frames("NP V NP", "wish")
      [%{class_id: "wish-62",
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
           [{:synrestrs, %{},
             [{:synrestr, %{type: "sentential", value: "-"}, []}]}]}]}]

      iex> VerbNet.find_frames(["NP", "V", "NP"], "wish")
      [%{class_id: "wish-62",
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
           [{:synrestrs, %{},
             [{:synrestr, %{type: "sentential", value: "-"}, []}]}]}]}]

      iex> VerbNet.find_frames("NP V NP", "foo")
      []

  """
  @spec find_frames(primary :: binary, member :: binary) :: list
  @spec find_frames(primary :: list, member :: binary) :: list
  def find_frames(primary, member) when is_list(primary) do
    find_frames(Enum.join(primary, " "), member)
  end

  @doc ~S"""
  Return complete raw map of an entire VerbNet class.

  On failed lookup, returns :invalid_class.
  """
  @spec class(class_id :: binary) :: map
  def class(class_id) do
    # To shut up the compiler and make docs generate properly...
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
    case class(class_id) do
      %{members: retval} -> retval
        _ -> :invalid_class
    end
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
      case class(class_id) do
        %{themroles: retval} -> retval
        _ -> :invalid_class
      end
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
      case class(class_id) do
        %{frames: retval} -> retval
        _ -> :invalid_class
      end
  end

  # Util method to remove compiler warnings re unused params AND allow ExDoc to generate properly.
  defp invalid_class(_class_id) do
    :invalid_class
  end

  # Internal lookup method called by pattern-matched function heads.
  defp aggregate_class_frames(class_ids, primary) do
    for class_id <- class_ids do
      frames(class_id) |> Map.get(primary) |> Map.put(:class_id, class_id)
    end
  end

end
