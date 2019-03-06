##  NAME

[![Build Status](https://travis-ci.org/swuecho/camelsnakekebab.svg?branch=master)](https://travis-ci.org/swuecho/camelsnakekebab)

## camelsnakekebab 

A Ocaml library for word case conversion

port of  https://metacpan.org/pod/String::CamelSnakeKebab 


## SYNPOSIS

```ocaml
(split_words "foo bar");;
["foo"; "bar"] 

(split_words "foo\n\tbar");;
["foo"; "bar"] 

(split_words "foo-bar");;
["foo"; "bar"] 

(split_words "fooBar");;
["foo"; "Bar"] 

(split_words "FooBar");;
["Foo"; "Bar"] 

(split_words "foo_bar");; 
["foo"; "bar"] 

(split_words "FOO_BAR");; 
["FOO"; "BAR"] 

(split_words "foo1");; 
["foo1"] 

(split_words "foo1bar");; 
["foo1bar"] 

(split_words "foo1_bar");;
["foo1";"bar"] 

(split_words "foo1Bar");;
["foo1";"Bar"] 


(upper_camel_case "flux_capacitor");;
"FluxCapacitor" 

(lower_camel_case "flux_capacitor");;
"fluxCapacitor" 

(lower_snake_case "ASnakeSlithersSlyly");; 
"a_snake_slithers_slyly" 

(lower_snake_case "address1");; 
"address1" 

(upper_snake_case "ASnakeSlithersSlyly");; 
"A_Snake_Slithers_Slyly"

(constant_case "I am constant");;
"I_AM_CONSTANT" 

(kebab_case "Peppers_Meat_Pineapple");;
"peppers-meat-pineapple" 

(http_header_case "x-ssl-cipher");; 
"X-SSL-Cipher"  
```

