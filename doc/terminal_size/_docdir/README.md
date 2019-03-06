[![Build Status](https://travis-ci.org/cryptosense/terminal_size.svg)](https://travis-ci.org/cryptosense/terminal_size)

# `Terminal_size`

## What is it?

You can use this small ocaml library to detect the dimensions of the terminal
window attached to a process. It contains the two following functions:

```ocaml
val get_rows : unit -> int option
val get_columns : unit -> int option
```

## How does it work?

Usually, to get this information, one would open a pipe from `tput cols` or
`stty size` and parsing the output. Instead, this uses the `ioctl` that these
commands use, `TIOCGWINSZ`.
