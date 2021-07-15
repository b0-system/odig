## v0.3.0 (2020-11-30)

- support MirageOS dual IPv4 and IPv6 stack

## v0.2.2 (2019-11-02)

- adapt to mirage interfaces (mirage-kv, mirage-clock, mirage-console 3.0.0)

## v0.2.1 (2019-03-02)

- lwt: don't report while reporting (otherwise out of memory).

## 0.2.0 (2018-10-27)

- support for syslog-message.1.0.0
  it split the `message` field of Syslog_message.t into `tag` and `content`
  use the name of Logs.src as tag when sending messages
- move build system to dune (#10 by @dra27)
- provide Logs_syslog.facility Logs.Tag.def to specify facility in log
  message, add ?facility as default facility to all reporters (reported in #7,
  fixed in #9 by @dra27)
- append ':' to source (reported in #6, fixed in #8 by @dra27)
- add missing dependency on unix for logs-syslog.unix (#4 by @dra27)

## 0.1.1 (2018-04-09)

- be honest about lwt.unix dependency in tls-syslog.lwt{.tls} (lwt 4.0 support)
- logs-syslog.lwt: no need to handle EAGAIN (already handled by Lwt_unix)

## 0.1.0 (2017-01-18)

- remove <4.03 compatibility
- Mirage: use STACK instead of UDP/TCP
- MirageOS3 support

## 0.0.2 (2016-11-06)

- Unix, TCP: wait (if something else reconnects) for 10 ms instead of 1s
- Lwt, UDP: remove unneeded mutex
- Lwt, TCP: lock in reconnect, close socket during at_exit
- Lwt, TLS: lock in reconnect, close socket during at_exit
- Mirage, TCP: respect ?framing argument
- Mirage: catch possible exceptions, print errors to console (now required)
- Mirage, TCP & TLS: lock in reconnect

## 0.0.1 (2016-10-31)

- initial release with Unix, Lwt, Mirage2 support