# ocaml-wtf8

WTF-8 is a superset of UTF-8 that allows unpaired surrogates.

From ES6 6.1.4, "The String Type":

> Where ECMAScript operations interpret String values, each element is
> interpreted as a single UTF-16 code unit. However, ECMAScript does not
> place any restrictions or requirements on the sequence of code units in
> a String value, so they may be ill-formed when interpreted as UTF-16 code
> unit sequences. Operations that do not interpret String contents treat
> them as sequences of undifferentiated 16-bit unsigned integers.

If we try to encode these ill-formed code units into UTF-8, we similarly
get ill-formed UTF-8. WTF-8 is a fun name for that encoding.

https://simonsapin.github.io/wtf-8/
