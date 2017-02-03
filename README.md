# VerbNet

[![Hex.pm](https://img.shields.io/hexpm/v/verbnet.svg)](https://hex.pm/packages/verbnet) [![Build Status](https://travis-ci.org/arpieb/verbnet.svg?branch=master)](https://travis-ci.org/arpieb/verbnet)

**VerbNet** provides a semantic map that allows an [NLP](https://en.wikipedia.org/wiki/Natural_language_processing) 
solution to take a tokenized and [part-of-speech (POS)](https://en.wikipedia.org/wiki/Part_of_speech) tagged sentence 
and attempt to map the semantics of the sentence (context, thematic roles, etc) using the identified main verb and a POS
pattern.

For example, the sentence, "I wished the children found," would be tokenized + tagged by an external parser into the 
pattern "NP V NP ADJ" using [Penn Treebank II tags](http://www.clips.ua.ac.be/pages/mbsp-tags) with a root verb of "wish."  
This subsequently could be matched to the following VerbNet frame which maps the parts of speech to thematic roles:

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
  [{:verbnet, "~> 0.1.0"}]
end
```

## Usage

The **VerbNet** package us intended to be used by NLP solutions to perform lookups or cross-references within the 
semantic network provided by the CSU VerbNet dataset (see `assets/verbnet` for license and any documentation).  Basic API overview is:

```elixir
# Return raw class map representation of class "wish-62" loaded from VerbNet file wish-62.xml.
VerbNet.class("wish-62")

# Return all verb members for the "wish-62" class.
VerbNet.members("wish-62")

# Return thematic roles associated with the "wish-62" class.
VerbNet.roles("wish-62")

# Return frames defined in the "wish-62" class.
VerbNet.frames("wish-62")

# Attempt to find a frame that matches the POS structure and root verb of a phrase.
VerbNet.find_frame("NP V NP", "wish")
```

## Contributing

All requests will be entertained, but the purpose of this package is to focus on providing services surrounding the 
VerbNet dataset specifically, and not to delve into the broader topic of NLP which will be left to other packages.

That being said, if there is a use case that leverages VerbNet data that would be helpful for researchers, please feel 
free to open an issue or fork and help out!

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/verbnet](https://hexdocs.pm/verbnet).

