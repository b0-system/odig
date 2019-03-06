# Offheap

`offheap` moves copies of OCaml values off the heap into memory managed by `malloc` and `free`, allowing them to be manually managed and reclaimed. Moving large objects off the heap can potentially improve performance as they are not reachable by the garbage collector, avoiding expensive traversals.

## Interface

* `val copy : ?alloc:alloc -> 'a -> 'a t`

Creates a copy of an object, returning a handle to it. The handle is required to free the object. The old value is still usable.

* `val get : 'a t -> 'a`

Returns a reference to the copied object from the handle.

* `val free : 'a t -> unit`

Frees the off-heap memory. All references to the copied object are invalid from this point onwards.

## Custom allocators

By default, a malloc-based allocator is used.
Custom allocators can be provided, however they must be implemented in C: copying cannot call back into OCaml code. Callbacks could potentially access the copied object or trigger a heap sweep which would fail since at the point of the call the headers of blocks in the old object are left in an inconsistent state. The custom allocator must implement the following two functions:

* `void *malloc(value allocator, size_t size)`
* `void free(value allocator)`

They must be stored in the first two fields of an `Abstract_tag` block. Additional data may be stored in other fields of the same block, which is passed to the allocator functions.

## Limitations

The object to be copied cannot reference non-Ocaml values (`Custom_tag` or `Abstract_tag`).

The builtin polymorphic comparison and hash functions do not work with off-heap objects anymore since they do not traverse off-heap objects.

## Acknowledgement

The implementation was inspired by the iterative traversal implemented in the `Obj` module of the OCaml runtime. This library was inspired by the existing `ancient` library, which is unable to handle large objects because of recursive traversals.

## License

The code is published under the MIT License.
