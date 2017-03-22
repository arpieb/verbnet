# VerbNet

[![Hex.pm](https://img.shields.io/hexpm/v/verbnet.svg)](https://hex.pm/packages/verbnet)  [![Build Status](https://travis-ci.org/arpieb/verbnet.svg?branch=master)](https://travis-ci.org/arpieb/verbnet)

The **VerbNet** package provides semantic framing lookups using the [VerbNet](https://verbs.colorado.edu/~mpalmer/projects/verbnet.html) dataset (see `assets/verbnet` for license and any documentation provided by the creators).  This allows an [NLP](https://en.wikipedia.org/wiki/Natural_language_processing) 
solution to take a tokenized and [part-of-speech (POS)](https://en.wikipedia.org/wiki/Part_of_speech) tagged sentence 
and attempt to map the semantics of the sentence (context, thematic roles, etc) using the identified root verb and a POS pattern.

For example, the sentence, "I wished the children found," would be tokenized + tagged by an external parser into the 
pattern "NP V NP ADJ" using [Penn Treebank II tags](http://www.clips.ua.ac.be/pages/mbsp-tags) with a root verb of "wish."  This subsequently could be matched to the following **VerbNet** frame which maps the parts of speech to thematic roles:

```
"NP V NP ADJ" => %{description: %{descriptionnumber: "8.1",
    primary: "NP V NP ADJ", secondary: "NP-VEN-NP-OMIT", xtag: "0.2"},
  examples: [["I wished the children found."]],
  semantics: [{:pred, %{value: "desire"},
    [{:args, %{},
      [{:arg, %{type: "Event", value: "E"}, []},
       {:arg, %{type: "ThemRole", value: "Experiencer"}, []},
       {:arg, %{type: "ThemRole", value: "Stimulus"}, []}]}]}],
  syntax: [{:np, %{value: "Experiencer"}, [{:synrestrs, %{}, []}]},
   {:verb, %{}, []},
   {:np, %{value: "Stimulus"},
    [{:synrestrs, %{},
      [{:synrestr, %{type: "np_ppart", value: "+"}, []}]}]}]},
```

## Installation

If [available in Hex](https://hex.pm/packages/verbnet), the package can be installed
by adding `verbnet` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:verbnet, "~> 0.3.0"}]
end
```

**NOTE:** Initial compilation of the package will take quite a while (~90-120s) due to the large number of function heads created and the amount of static data being embedded in code.  If anyone has suggestions as to how to speed this up, _please_ open an issue or better yet create a pull request!  On the other hand, lookups are incredibly fast and concurrent-friendly (static data in pattern-matched function heads), so maybe this isn't such a hardship. :)

## Usage

Basic API overview:

```elixir
# Return raw class map representation of class "wish-62" loaded from VerbNet file wish-62.xml.
VerbNet.class("wish-62")

# Return all verb members for the "wish-62" class.
VerbNet.members("wish-62")

# Return thematic roles associated with the "wish-62" class.
VerbNet.roles("wish-62")

# Return frames defined in the "wish-62" class.
VerbNet.frames("wish-62")

# Attempt to find frame(s) that match the POS structure and root verb of a phrase.
VerbNet.find_frames("NP V NP", "wish")
```

## Contributing

All requests will be entertained, but the purpose of this package is to focus on providing services surrounding the 
VerbNet dataset specifically, and not to delve into the broader topic of NLP which will be left to other packages.

That being said, if there is a use case that leverages VerbNet data that would be helpful for researchers, please feel 
free to open an issue or fork and help out!

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/verbnet](https://hexdocs.pm/verbnet).

