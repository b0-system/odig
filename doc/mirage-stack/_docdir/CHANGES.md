### v1.3.0 2018-09-15

- remove unused type `netif` and `'netif config` from V4 signature
- remove `'netif stackv4_config` and `socket_stack_config`
- adjust to mirage-protocols 1.4.0: remove `ip` from UDPV4 and TCPV4

### v1.2.0 2017-09-06

- add an optional argument ?keepalive to `listen_tcpv4` which allows TCP
  keepalives on accepted connections.
- jbuilder is now a build dependency

### v1.1.0 2017-06-16

- port to Jbuilder

### v1.0.0 2016-12-29

- import V4 module type from mirage-types and mirage-types-lwt, where it was STACKV4
