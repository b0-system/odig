## syslog-message - Syslog message parser

1.1.0

This is a library for parsing and generating RFC 3164 compatible Syslog messages.

## Documentation

[![Build Status](https://travis-ci.org/verbosemode/syslog-message.svg?branch=master)](https://travis-ci.org/verbosemode/syslog-message)

[API documentation](https://verbosemode.github.io/syslog-message/doc/) is available online.

```ocaml
match Ptime.of_date_time ((1970, 1, 1), ((0, 0, 0), 0)) with
| Some ts -> Syslog_message.decode ~ctx:{timestamp=ts; hostname="-"; set_hostname=false} "<133>Oct  3 15:51:21 server001: foobar"
| None -> failwith "Failed to parse Syslog message";;
- : Syslog_message.t option =
Some {Syslog_message.facility = Syslog_message.Local0; severity = Syslog_message.Notice; timestamp = <abstr>;
  hostname = "server001"; message = "foobar"}
```

## Installation

This library can be installed with `opam`: `opam install syslog-message`

## Testing

A test suite using qcheck is provided: `opam install --build-test syslog-message`
