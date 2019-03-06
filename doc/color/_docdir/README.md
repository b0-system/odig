## color: converts between different color formats

Library that converts between different color formats. Right now it deals with
HSL, HSLA, RGB and RGBA formats.

The goal for this library is to provide easy handling of colors on the web, when working
with `js_of_ocaml`.

## Examples

```ocaml
# Color.to_hexstring (Color.of_rgb 12 121 229);;
- : "#0c79e5"
```

The library uses the color type from [Gg](https://github.com/dbuenzli/gg).

```ocaml
# Color.to_css_hsla (Gg.Color.red);;
- : string = "hsl(0.00, 100.00%, 50.00%)"

# Color.to_css_rgba (Gg.Color.red);;
- : string = "rgb(255, 0, 0)"

# Color.to_hexstring (Color.complementary (Gg.Color.red));;
- : string = "#00ffff"
```

## Credit

Based on [purescript-colors](https://github.com/sharkdp/purescript-colors)
