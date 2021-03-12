# Change Log

## [0.6.4.pre] - unreleased

- Exposes `PostgresAdapter#query_type_map` to extend PG type mapping.
- Defers building type maps for PostgreSQL connections, to avoid bugs with ActiveRecord.

## [0.6.3] - 2021-03-11

- Supports transaction flow control using any flavour SQL with `Ensql.transaction` and `Ensql.rollback!`.
- Eliminates cyclic dependencies for `Error` and `Ensql.adapter`.
- Tidies specs.
- Adopts [standardrb](https://github.com/testdouble/standard).

## [0.6.2] - 2021-03-09

- Adds a specialised adapter for PostgreSQL.
- Uses instances instead of modules for SequelAdapter and ActiveRecordAdapter. The use of the (now) classes as adapters is deprecated.
- Adds connection pool wrappers for ActiveRecord and Sequel.
- Ensures SQL#each_row returns nil.
- Makes adapter attribute thread-safe.

## [0.6.1] - 2021-02-25

- Enables the use of streaming with the SequelAdapter
- Improves performance of #first_row and #each_row
- Tests against Sequel 5.9

## [0.6.0] - 2021-02-15

- Initial release
