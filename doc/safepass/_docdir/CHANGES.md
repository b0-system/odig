v3.0 2018-06-28
---------------

  * Patches by Marek Kubica:
    - Port to `Dune` and remove all generated files.
    - Allow picking different variants of Bcrypt hashes
      (implies new major version number).
    - Use unbuffered IO to read only required number of bytes from `/dev/urandom`.

v2.0 2016-06-21
---------------

  * Patch by Tim Cuthbertson adding support for compiling with Mirage-xen.
  * Do not use `-Wmissing-prototypes`.
  * Type renaming: `hash_t` -> `hash` (implies new major version number).
  * Do not use external for identity functions.

v1.3 2014-07-25
---------------

  * Patches by Jonathan Curran:
    - Update to oasis format 0.4 to allow usage of C compiler flags.
    - Enable optimizations via compiler flags (same as C code).
      This brings a healthy speed-up to the library.
    - Update `src/crypt_blowfish.c` to version 1.3 from
      [openwall.com/crypt](http://www.openwall.com/crypt)

v1.2 2012-10-08
---------------

  * Add OASIS generated files that were missing from previous release.

v1.1 2012-10-07
---------------

  * Library's findlib name changed to just 'safepass'.

v1.0.1 2012-08-02
-----------------

  * Fix problem on i386 systems without `_BF_body_r` in libc.

v1.0 2012-07-09
---------------

  * First stable release.

