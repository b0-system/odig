# 0.2.0

* Switch to using types from [Gg](http://erratique.ch/software/gg)
* Parse CSS hex color representation
* Add some basic colors (black, white and graytone)
* Add utilities to modify a color
  - `rotate_hue` (Rotates the hue of a color by given angle)
  - `complementary` (Rotates hue by 180 degree)
  - `lighten` (Lightens a color by given amount)
  - `darken` (Darks a color by given amount)
  - `saturate` (Increases saturation by given amount)
  - `desaturate` (Decreases saturation by given amount)
  - `light` (tells if a color is perceived as light)
  - `contrast_ratio` (returns contrast ratio between colors)
  - `relative_luminance` (returns luminance of a color)
  - `brightness` (returns perceived brightness of a color)
  - `readable` (checks if a text color is readable on a backgroun)
  - `text_color` (returns a suitable text color for given background color)

# 0.1.0

Initial release.

* Conversion function from hsl, hsla, rgb, rgba, rgb', rgba'
* Converts color representation to hexstring
