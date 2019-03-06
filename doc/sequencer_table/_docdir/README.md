Sequencer_table
===============

`Sequencer_table` is an `Async` data structure that combines a
`Hashtbl` and a `Sequencer`.  A sequencer table is a hash table with
one sequencer for each key, used to process jobs in sequence for that
key.  Sequencers are automatically created and destroyed as needed.
