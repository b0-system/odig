# CharInfo\_width

Determine column width for a character.

# How to use

`CharInfo_width.width c` returns the column width of `c` where `c` is of type `Camomile.UChar.t` and the value returned is of type `int`.

This module is implemented purely in OCaml and the `width` function follows the prototype of POSIX's wcwidth. i.e. If `c` is a printable character, the value is at least 0. If `c` is null character (L'\0'), the value is 0. Otherwise, -1 is returned. The `width_exn` function, when encounter an unprintable character, it raises `Failure "unprintable character"` instead of returning -1.

By default, the `width` and `width_exn` function is compatible with ncursesw, ncursesw based CLIs, terminals. The way they consider the width of a character is the same.

An optional parameter, `cfg`, can extend extra width info. The current width info table of ncursesw, xterm, xterm-compatible terminal is inadequate and limited, so is the default cfg of this module. When implement raw mode command-line interface, e.g. readline, a text editor, better extend extra width info by `cfg`. An on going sample repository of width table is here: [charInfo\_width\_extra](https://bitbucket.org/zandoye/charinfo_width_extra)

This module also provides a functor, `CharInfo_width.String`. This functor accepts a `Camomile.UnicodeString` compatible module to calculate the width of a unicode string. The returned value is either `Ok width` or `Error pos-of-unprintable-character`.


# Document

The document is available [here](https://zandoye.bitbucket.io/doc/_html/charInfo_width/).

