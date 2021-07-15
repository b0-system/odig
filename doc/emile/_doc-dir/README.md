## Emile (& [Images](https://youtube.com/watch?v=S70NaQqAfaw))

[![Build Status](https://travis-ci.org/dinosaure/emile.svg?branch=master)](https://travis-ci.org/dinosure/emile)
![MirageOS](https://img.shields.io/badge/MirageOS-%F0%9F%90%AB-red.svg)

Emile is a library to parse an e-mail address in OCaml. This project is an
extraction of [mrmime](https://github.com/mirage/mrmime.git).

This implementation follow some RFCs:
- [RFC 822](https://www.ietf.org/rfc/rfc822.txt)
- [RFC 2822](https://www.ietf.org/rfc/rfc2822.txt)
- [RFC 5321](https://www.ietf.org/rfc/rfc5321.txt) (domain part)
- [RFC 5322](https://www.ietf.org/rfc/rfc5322.txt)
- [RFC 6532](https://www.ietf.org/rfc/rfc6532.txt)

We handle UTF-8 ([RFC 6532](https://www.ietf.org/rfc/rfc6532.txt)), domain
defined on the SMTP protocol ([RFC 5321](https://www.ietf.org/rfc/rfc5321.txt)),
and general e-mail address purpose (RFC 822, RFC 2822, RFC 5322) __without__
_folding-whitespace_.

### Folding whitespace

According RFC 822, an e-mail address into an e-mail can be splitted by a
_folding-whitespace_. However, this kind of form is not an usual case where user
mostly wants to parse input from a form (for example). At the end, `emile` is
not able to parse this kind of input:

```
A Group(Some people)
   :Chris Jones <c@(Chris's host.)public.example>,
     joe@example.org,
 John <jdoe@one.test> (my dear friend); (the end of the group)"
```

However, a pre-process (like
[unstrctrd](https://github.com/dinosaure/unstrctrd)) can _fold_ input and give
you an usual output. `emile` can not be used into an e-mail context without this
kind of pre-process.

### Domain

Then, for domain part (explained on RFC 5321 - SMTP protocol), we handle this
kind of domain (IPv4 and IPv6 domain) with
[ipaddr](https://github.com/mirage/ipaddr.git):

```
first.last@[12.34.56.78]
first.last@[IPv6:1111:2222:3333::4444:12.34.56.78]
```

It's possible to notify multiple domains for one local-part like this:
 
```
<@a.com,b.com:john@doe.com>
```

It's a valid form according [RFC 882](https://www.ietf.org/rfc/rfc822.txt).

### Comments

Even if we don't handle the _folding-whitespace_, we are able to discard
comments.

```
a(a(b(c)d(e(f))g)h(i)j)@iana.org
```

## Advise

If you think it's easy to parse an e-mail address, you should look
[tests](https://github.com/mirage/emile/blob/master/test/test.ml).
