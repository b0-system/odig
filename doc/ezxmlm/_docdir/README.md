## ezxmlm -- combinators for parsing and selection of XML structures

[![Build Status](https://travis-ci.org/mirage/ezxmlm.svg?branch=master)](https://travis-ci.org/mirage/ezxmlm)

An "easy" interface on top of the Xmlm [1] library.  This version provides more
convenient (but far less flexible) input and output functions that go to and
from [string] values.  This avoids the need to write signal code, which is
useful for quick scripts that manipulate XML.
   
More advanced users should go straight to the Xmlm library and use it directly,
rather than be saddled with the Ezxmlm interface.  Since the types in this
library are more specific than Xmlm, it should interoperate just fine with it
if you decide to switch over.

* Online docs: <https://mirage.github.io/ezxmlm>
* Source Code: <https://github.com/mirage/ezxmlm>
* Discussion: <https://discuss.ocaml.org> in the Ecosystem category
* Bugs: <https://github.com/mirage/ezxmlm/issues>

# Example

In the toplevel, here's an example of how some XHTML can be selected out
quickly using the Ezxmlm combinators.  Note that this particular HTML has
been post-processed into valid XML using `xmllint --html --xmlout`.

```
# #require "ezxmlm" ;;
# open Ezxmlm ;;
# let (_,xml) = from_channel (open_in "html/variants.html") ;;
# member "html" xml |> member "head" |> member_with_attr "meta" ;;
- : Xmlm.attribute list * nodes = ([(("", "name"), "generator"); (("", "content"), "DocBook XSL Stylesheets V1.78.1")], [])
# member "html" xml |> member "head" |> member "title" |> data_to_string;;
- : string = "Chapter 6. Variants"                                                                                                                                                                                                                                                                                          
```

Ez peezy lemon squeezy!

[1] https://github.com/dbuenzli/xmlm
