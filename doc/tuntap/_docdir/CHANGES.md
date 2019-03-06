## v1.7.0 2019-01-1

* Do not specify `ipv4:false` for the conversion function for IP addresses.
  This supports the ipaddr.3.0.0+ interface (#29 by @hannesm)
* Port build from Jbuilder to Dune (#30 by @avsm)
* Add tests in Travis for OCaml 4.07 (#30 by @avsm)
* Update opam metadata to 2.0 format (#30 by @avsm)

## v1.6.1 2018-05-17

* Fix build on OpenBSD (#28 via @hannesm).

## v1.6.0 2017-11-11

* Bring up interface if it was not already up (#24 via @sevenEng).

## v1.5.0 2017-06-24
* port to Jbuilder
* build all the tests by default.
* possibly fix bytecode as well, which had a typo in the old rules.

## v1.4.1 2017-02-20
* fix linking of binaries using tuntap (`-ltuntap_stubs`) (#21 by Hannes Mehnert)

## v1.4.0 2017-02-09
* Port to topkg (#20) (Gabriel Jaldon and Hannes Mehnert).
* When closing devices, call `open` with `~persist:false` (#17 by Mindy Preston).
* Remove deprecated use of `Lwt_unix.run` from tests.

## v1.3.0 2015-06-07
* Do not leak a file descriptor per tun interface (#12 via Justin Cormack)
* Avoid the need for root access for persistent interfaces by not calling
  `SIOCSIFFLAGS` if not needed (#13 via Justin Cormack).
* Use centralised Travis scripts.
* Work around OS X bug in getifaddrs concerning lo0@ipv6 (#14)
* Force a default of non-blocking for the Linux tuntap file descriptor.
  This works around a kernel bug in 3.19+ that results in 0-byte reads
  causing processes to spin (https://bugzilla.kernel.org/show_bug.cgi?id=96381).
  Workaround is to open the device in nonblock mode, via Justin Cormack.

## v1.2.0 2015-09-01
* `set_ipaddr` renamed to `set_ipv4` since it can only set IPv4 addresses.
* Improved `getifaddrs` interface to an association list iface -> addr.
* Dropped OCaml < 4.01.x support.
* Added convenience functions `gettifaddrs_v{4,6}`, `v{4,6}_of_ifname`.

## v1.1.0 2014-11-24
* Do not change the `persist` setting if unspecified when
  opening a new tun interface (#9 from Luke Dunstan).

## v1.0.0 2014-03-02
* Improve error messages to distinguish where they happen.
* Install otunctl command-line tool to create persistent tun/taps.
* Build debug symbols, annot and bin_annot files by default.
* getifaddrs now lists IPv6 as well, and return a new type.
* set_ipv6 is now called set_ipaddr, and will support IPv6 in the
  future (currently unimplemented).

## v0.7.0 2013-09-28
* Add FreeBSD support.
* Add Travis continuous integration scripts.

## v0.6 2013-08-07
* Remove dependency on cstruct
* Add dependency on ipaddr
* Removed redundant functions (now in ipaddr)

## v0.5 2013-05-30
* Add a non-blocking packet dumper test.
* New function getifaddrs, binding to getifaddrs(3).
* New version of tunctl, using cmdliner.
* Add a set_ipv4 test to check the behaviour of set_ipv4.

## v0.4 2013-05-25
* Fixed MacOS X tuntap support.

## v0.3 2013-05-22
* First public release.
