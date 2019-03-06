# Changelog

## WIP

* Fix to work with safe-string flag/compilers (thanks Jacques-Pascal Deplaix)

## 0.3.5

## 0.3.4

* Port to jbuilder (thanks Rudi Grinberg)
* *Drop support of ocaml-4.01* (due to port to jbuilder) and run CI against ocaml-4.04
* Force read_reply to be atomic (thanks Jams Long)
* Pass hints to getaddrinfo (thanks Doğan Çeçen)

## 0.3.3

* Fix fd leak for `Redis_lwt.Client.with_connection`, thanks @domsj
* Fix socket leak on connection failure, thanks @ahrefs

## 0.3.2

Fixed EX/PX bug with SET (see issue #34, thanks @briancaine).

Introduce string and float bound type.

Following commands were added or fixed (due to bound type introduction):

* ZRANGEBYSCORE
* ZRANGEBYLEX
* ZREVRANGEBYSCORE
* ZREVRANGEBYLEX
* ZREMRANGEBYLEX
* ZREMRANGEBYSCORE
* ZREMRANGEBYRANK
* ZCARD
* ZCOUNT
* ZLEXCOUNT
* ZRANK
* ZREVRANK

## 0.3.1

Expose stream type for both lwt and sync backends (see issue #32, thanks @acs1)

## 0.3.0

Now package contains 3 modules: `Redis`, `Redis_lwt` and `Redis_sync`.

* `Redis` - `Client`/`Cache`/`Mutex` modules type signatures
* `Redis_sync` - synchronous implementation of client library
* `Redis_lwt` - Lwt-based implementation of client library

Commands implementations:

* A few improvements to the sorted set operations, thanks @domsj
* Add PFADD/PFCOUNT/PFMERGE
* Add HSCAN/HSTRLEN/HINCRBYFLOAT commands
* Add MIGRATE command
* Add PSETEX and OBJECT command
* Add PUNSUBSCRIBE/PSUBSCRIBE commands, thanks @j0sh.
* Add MSET/MSETNX/MGET commands
* Add ZSCORE, thanks @ipfix
* Fail explicitly when PING command was failed

Testing changes:

* Rework all test cases due IO module usage, thanks @rgrinberg
* Fix test exit code to return non-zero code on failure

Infrastructure changes:

* String.create -> Bytes.create to silence warning on recent OCaml versions
* Require OCaml version to be >= 4.01.0, thanks @hcarty
* Replace `Lwt_chan` use with `Lwt_io`
* Properly resolve string hostnames, e.g. localhost, google.com etc.., thanks @toots
