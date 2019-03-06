Type-safe GraphQL queries in OCaml
-----------------------------------------------

![Build Status](https://travis-ci.org/andreas/ppx_graphql.svg?branch=master)

Given a GraphQL schema (introspection query response) and a GraphQL query, `ppx_graphql` generates three values: (1) a GraphQL query (2) a function to construct the associated query variables, and (3) a function for parsing the GraphQL JSON response into a typed value (object type).

Here's an example of using `ppx_graphql` and the generated values (the schema is shown at the top in [GraphQL Schema Language](https://raw.githubusercontent.com/sogko/graphql-shorthand-notation-cheat-sheet/master/graphql-shorthand-notation-cheat-sheet.png)):

```ocaml
(*
enum ROLE {
  USER
  ADMIN
}

type User {
  id: ID!
  role: ROLE
  contacts: [User!]!
}

type Query {
  user(id: ID!): User
}

schema {
  query: Query
}
*)

let query, kvariables, parse = [%graphql {|
  query FindUser($id: ID!) {
    user(id: $id) {
      id
      role
      contacts {
        id
      }
    }
  }
|}] in
(* ... *)
```

In this example, the following values are generated:

- `query` (type `string`) is the GraphQL query to be submitted. Currently it's an unmodified version of the string provided to `%graphql`, but it will likely be modified in the future, e.g. to inject `__typename` for interface disambiguation.
- `kvariables` (type `(Yojson.Basic.json -> 'a) -> id:string -> unit -> 'a`) is a function to construct the JSON value to submit as query variables ([doc](http://graphql.org/learn/serving-over-http/#post-request)). Note that the first argument is a continuation to handle the resulting JSON value -- this makes it easier to write nice clients (see more below). The type is extracted from the query. Required variables appear as labeled arguments, optional variables appear as optional arguments.
- `parse` is a function for parsing the JSON response from the server and has the type:
  
  ```
  Yojson.Basic.json ->
    <user:
      <id: string;
      role: [> `USER | `ADMIN] option;
      contacts: <id: string> list>
    >
  ```
  This type captures the shape of the GraphQL response in a type-safe fashion based on the provided schema. Scalars are converted to their OCaml equivalent (e.g. a GraphQL `String` is an OCaml `string`), nullable types are converted to `option` types, enums to polymorphic variants, lists to list types and GraphQL objects to OCaml objects. Note that this function will likely return a `result` type in the future, as the GraphQL query can fail.

With the above, it's possible to write quite executable queries quite easily:

```ocaml
let executable_query (query, kvariables, parse) =
  kvariables (fun variables ->
    let response_body = (* construct HTTP body here and submit to GraphQL endpoint *) in
    Yojson.Basic.of_string response_body
    |> parse
  )

let find_user_role = executable_query [%graphql {|
  query FindUserRole($id: ID!) {
    user(id: $id) {
      role
    }
  }
|}]
```
Here  `find_user_role` has the type ```id:string -> unit -> <user: <role: [`USER | `ADMIN] option> option>```. See [`github.ml`](https://github.com/andreas/ocaml-graphql-server/blob/ppx/ppx_graphql/examples/github.ml) for a real example using `Lwt` and `Cohttp`.

`[%graphql ...]` expects a file `schema.json` to be present in the same directory as the source file. This file should contain an introspection query response.

For use with jbuilder, use the `preprocess`- and `preprocessor_deps`-stanza:

```
(executable
  (preprocess (pps (ppx_graphql)))
  (preprocessor_deps ((file schema.json)))
  ...
)
```

### Unions

When a field of type union is part of your GraphQL query, you must select `__typename` on that field, otherwise you will get a runtime error! This limitation is intended to be solved in the future.

Example:

```ocaml
let _ = [%graphql {|
  query SearchRepositories($query: String!) {
    search(query: $query, type: REPOSITORY, first: 5) {
      nodes {
        __typename
        ...on Repository {
          nameWithOwner
        }
      }
    }
  }
|}]
```

### Limitations and Future Work

- No support for input objects
- No support for interfaces
- No support for custom scalar types
- Poor error handling
- Error reporting should be improved
- Path to JSON introspection query result is hardcoded to "schema.json"
- Assumes the query has already been validated
