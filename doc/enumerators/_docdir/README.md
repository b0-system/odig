[![Build status](https://api.travis-ci.org/cryptosense/enumerators.svg)](https://travis-ci.org/cryptosense/enumerators)

Finite lazy enumerators
=======================

The *enumerators* library enables you to work with large sequences of elements.

Example
-------

Let's assume you want to scan ports of a few hosts on your network.  Your first task is to
enumerate those ports.  Naturally, as the list can grow big, you don't want to have them
all in memory at the same time.  This is were this library comes into play.

In this example, targets have the type `string * int` where the first element is the IP
address and the second element is the network port.  Here is a function to print such a
target:

```ocaml
let print_target (ip, port) =
  Printf.printf "[%s]:%d\n" ip port
```

The following instructions will enable you to get a listing of the targets:

  * Define the address enumerator from a list of strings with `make`.
  * Define the port enumerator with `range`.
  * Define the enumerator for targets as a cartesian product of the addresses and the
    ports with `product`.
  * Iterate over this final enumerator to print each element.

Here's how you can do it:

```ocaml
let () =
  let addresses = Enumerator.make ["2001:db8::1"; "2001:db8::2"] in
  let ports = Enumerator.range 1 1024 in
  let targets = Enumerator.product addresses ports in
  Enumerator.iter print_target targets
```

You should get the following output:

```
[2001:db8::1]:1
[2001:db8::2]:1
[2001:db8::1]:2
[2001:db8::2]:2
[2001:db8::1]:3
[2001:db8::2]:3
...
```

Licensing
---------

This library is available under the 2-clause BSD license. See `LICENSE.md` for more information.
