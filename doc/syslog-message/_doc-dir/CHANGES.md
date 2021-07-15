## 1.1.0 (2019-04-14)

* additonal conversion and pretty printer functions (#23, by @vbmithr)

## 1.0.0 (2018-10-14)

* Warning: encode function no longer truncates messages to 1024 bytes by default
* split message part into tag and content (#20, by @hannesm)
* use result types instead of option (#20, by @hannesm)
* remove transport-dependent length check from encode (#20, by @hannesm)
* switch build system to Dune (#19, by @dra27)
* add encode_local for sending to local syslog (#17, by @dra27)
* forgot to thank @hannesm, @Leonidas-from-XIV for past contributions

## 0.0.2 (2016-10-29)

* simplify API: no set_hostname, hostname anymore #11
* introduce Rfc3164_timestamp module #11
* parse is now decode, to_string encode #11
* pp_string is now to_string #11
* provide pp : Format.formatter -> t -> unit
* remove int_to_severity/severity_to_int/int_to_facility/facility_to_int #11
* use topkg instead of oasis
* cleanups #8 #9

## 0.0.1 (2016-03-24)

* Initial release supporting RFC 3164
