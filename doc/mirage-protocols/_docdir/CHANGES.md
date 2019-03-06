### v1.4.1 2019-01-10

- ipaddr3 compatibility

### v1.4.0 2018-09-15

- remove unused types, since `connect` no longer in signatures (since Mirage3)
  `netif` from ETHIF
  `ethif` and `prefix` from IP
  `ip` from UDP and TCP

### v1.3.0 2017-09-06

- add support for TCP keepalives by changing the signature of the
  `TCP.input` function
- jbuilder is now a build dependency

### v1.2.0 2017-06-15

- port build to Jbuilder

### v1.1.0 2016-03-02

- require an mtu function in the ETHIF module type.

### v1.0.0 2016-12-29

- import ETHIF, ARP, IP, IPV4, IPV6, TCP, UDP, ICMP module types from mirage-types and mirage-types-lwt
