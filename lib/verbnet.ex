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
  |> Task.async_stream(VerbNet.XML, :process_xml, [], timeout: 10_000)
  |> Enum.to_list()
  |> Enum.map(fn({:ok, class_list}) -> class_list end)
  |> List.flatten()

  # Process each class extracted from the XML, generate basic class info lookups and collect all frame-member mappings.
  IO.puts("Processing #{Enum.count(classes)} VerbNet classes")
  all_frames = for {class_id, sections} <- classes do
    # Define basic lookup functions for this VerbNet class.
    def class(unquote(class_id)), do: unquote(Macro.escape(sections))
    def members(unquote(class_id)) do
      case class(unquote(class_id)) do
        %{members: retval} -> retval
        _ -> invalid_class(unquote(class_id))
      end
    end
    def roles(unquote(class_id)) do
      case class(unquote(class_id)) do
        %{themroles: retval} -> retval
        _ -> invalid_class(unquote(class_id))
      end
    end
    def frames(unquote(class_id)) do
      case class(unquote(class_id)) do
        %{frames: retval} -> retval
        _ -> invalid_class(unquote(class_id))
      end
    end

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
  for {{primary, member}, class_ids} <- all_frames do
#    IO.puts("#{primary}\t#{member}\t#{class_ids}")
#    def find_frame(unquote(primary), unquote(member)) do
#      find_frames(unquote(primary), unquote(class_ids))
#    end
  end

  # End timer
  elapsed = (System.monotonic_time() - start) |> System.convert_time_unit(:native, :seconds)
  IO.puts("Codified VerbNet classes in #{elapsed}s")

  @doc ~S"""
  Return semantic frame from VerbNet that matches the provided primary POS pattern and class member.

  On failed lookup, returns :no_match.

  ## Examples

      iex> VerbNet.find_frame("NP V NP", "wish")
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

      iex> VerbNet.find_frame(["NP", "V", "NP"], "wish")
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

  # Util method to return :invalid_class, yet allow function specs to provide useful help.
  defp invalid_class(_class_id) do
    :invalid_class
  end

  # Util method to return ::no_match, yet allow function specs to provide useful help.
  defp no_match(_primary, _member) do
    :no_match
  end

  # Internal lookup method called by pattern-matched function heads.
  defp find_frames(primary, class_ids) do
    for class_id <- class_ids do
      frames(class_id) |> Map.get(primary) |> Map.put(:class_id, class_id)
    end
  end

end
