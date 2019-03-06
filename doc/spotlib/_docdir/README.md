# Spotlib

Yet another extension of OCaml standard library.

## Module name convension

* `X.Open`: Recommended to open it when `X` is used
* `X.Pervasives`: They are included in `Spotlib.Spot`. Opening `Spotlib.Spot` make them available.

## Function name convension

Functions of stdlib are kept as they are. Only the exception is the conversions of non tail recursions to tail recursions.

### Tail recursion

Non tail recursive functions in stdlib _may_ be replaced by tail recursive equivalents. In that case, the original functions `xxx` in stdlib should be accessible by `xxx_ntr`.

### Exception

Some functions `xxx` do not raise exceptions even for strange inputs.
`xxx_exn` may throw exceptions for the strange inputs.

For example, `List.take 10 [] = []` following the behaviour of Haskell's `take`.
`take_exn` throws `Invalid_argument "List.take"` instead.

### Option

Many stdlib functions `xxx` throw exceptions `Not_found` when searching fails.
`xxx_opt` returns `None` instead.

### Default

Many stdlib functions may raise exceptions for some inputs.
`xxx_def` never throws exceptions for such inputs.
Ex. `String.sub` and `String.sub_default`:
`String.sub "hello" 3 5` throws an exception, but
`String.sub_default "hello" 3 5 = "lo"`.

## Function type convension

* No labels for basic functions. Proposes to use flip, flip2... instead.
