# Ezsqlite

Simplfied bindings to SQLite3 for OCaml

### SQLite3

The following compile-time flags have been set:

    #define SQLITE_ENABLE_COLUMN_METADATA 1
    #define SQLITE_DEFAULT_FOREIGN_KEYS 1
    #define SQLITE_DEFAULT_AUTO_VACUUM 1
    #define SQLITE_ENABLE_JSON1 1
    #define SQLITE_ENABLE_RTREE 1
    #define SQLITE_ENABLE_SESSION 1
    #define SQLITE_THREADSAFE 2

## Dependencies

- topkg
- hex
- C compiler

## Installation

    opam install ezsqlite

## Testing

    jbuilder runtest

## Documentation

See `lib/ezsqlite.mli`
