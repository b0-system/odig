Pecu (PQ/QP - Quoted Printable)
-------------------------------

Pecu is a little library to encode and decode quoted-printable according to
[RFC2045](https://tools.ietf.org/html/rfc2045) (§ 6.7). It provides a
non-blocking encoder/decoder and ensure to respect the 80 characters rule. It
provides a fuzzer which test isomorphism between encoder and decoder (and if we
respect correctly the 80 characters rule).

This project is a part of an encoder/decoder of e-mail.

Decoder can decode input which does not respect 80 characters rule but it
signals to the client if this case appear - which can be an attack entry point.
By this way, the decoder provide a best-effort case to the client.
