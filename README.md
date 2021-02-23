# Ensql

Ensql lets you write SQL for your application the safe and simple way. Ditch your ORM and embrace the power and
simplicity of writing plain SQL again.

  * **Write exactly the SQL you want.** Don't limit your queries to what's in the Rails docs. Composable scopes and
    dynamic includes can cripple performance for non-trivial queries. Break through the ORM abstraction and unlock the
    power of your database with well-structured SQL and modern database features.

  * **Keep your SQL in its own files.** Just like models or view templates, it makes sense to organise your SQL on its
    own terms. Storing the queries in their own files encourages better formatted, well commented, literate SQL. It also
    leverages the syntax highlighting and autocompletion available in your editor. Snippets of HTML scatter through .rb
    files is an awkward code smell, and SQL is no different.

  * **Do more with your database.** Having a place to organise clean and readable SQL encourages you to make the most of it.
    In every project I've worked on I've been able to replace useful amounts of imperative ruby logic with a declarative
    SQL query, improving performance and reducing the opportunity for type errors and untested branches.

  * **Safely interpolate user-supplied data.** Every web developer knows the risks of SQL injection. Ensql takes a
    fail-safe approach to interpolation, leveraging the underlying database adapter to turn ruby objects into properly
    quoted SQL literals. As long as user-supplied input is passed as parameters, your queries will be safe and
    well-formed.

  * **Use your existing database connection.** Ensql works with ActiveRecord or Sequel so you don't need to manage a
    separate connection to the database.

```ruby
# Run adhoc statements
Ensql.run("SET TIME ZONE 'UTC'")

# Run adhoc D/U/I statements and get the affected row count
Ensql.sql('DELETE FROM logs WHERE timestamp < %{expiry}', expiry: 1.month.ago).count # => 100

# Organise your SQL and fetch results as convenient Ruby primitives
Ensql.sql_path = 'app/sql'
Ensql.load_sql('customers/revenue_report', params).rows # => [{ "customer_id" => 100, "revenue" => 1000}, … ]

# Easily retrive results in the simplest shape
Ensql.sql('SELECT count(*) FROM users').first_field # => 100
Ensql.sql('SELECT id FROM users').first_column # => [1, 2, 3, …]
Ensql.sql('SELECT * FROM users WHERE id = %{id}', id: 1).first_row # => { "id" => 1, "email" => "test@example.com" }

# Compose multiple queries with fragment interpolation
all_results     = Ensql.load_sql('results/all', user_id: user.id)
current_results = Ensql.load_sql('results/page', results: all_results, page: 2)
total           = Ensql.load_sql('count', subquery: all_results)
result = { data: current_results.rows, total: total.first_field }
```

[Full Documentation](https://rubydoc.info/gems/ensql/Ensql/SQL)

## Installation

Add this gem to your Gemfile by running:

    $ bundle add ensql

Or install it manually with:

    $ gem install ensql

## Usage

Typically, you don't need to configure anything. Ensql will look for Sequel or ActiveRecord (in that order) and load the
appropriate adapter. You can override this if you need to, or configure your own adapter. See [Ensql::Adapter](https://rubydoc.info/gems/ensql/Ensql/Adapter) for
details of the interface.

```ruby
Ensql.adapter = Ensql::ActiveRecordAdapter # Will use ActiveRecord instead
```

SQL can be supplied directly or read from a file. You're encouraged to organise all but the most trivial statements in
their own *.sql files, for the reasons outlined above. You can organise them in whatever way makes most sense for your
project, but I've found sorting them into directories based on their purpose works well. For example:

    app/sql
    ├── analytics
    │   └── results.sql
    ├── program_details
    │   ├── widget_query.sql
    │   ├── item_query.sql
    │   ├── organisation_query.sql
    │   └── test_query.sql
    ├── reports
    │   ├── csv_export.sql
    │   ├── filtered.sql
    │   └── index.sql
    ├── redaction.sql
    ├── count.sql
    └── set_timeout.sql

### Interpolation

All interpolation is marked by `%{}` placeholders in the SQL. This is the only place that user-supplied input should be
allowed. Only various forms of literal interpolation are supported - identifier interpolation is not supported at this
stage.

There are 4 types of interpolation, see [Ensql::SQL](https://rubydoc.info/gems/ensql/Ensql/SQL) for details.

  1. `%{param}` interpolates a Ruby object as a SQL literal.
  2. `%{(param)}` expands an array into a list of SQL literals.
  3. `%{param( nested sql )}` interpolates the nested sql with each hash in an array.
  4. `%{!sql_param}` only interpolates Ensql::SQL objects as SQL fragments.

```ruby
# Interpolate a literal
Ensql.sql('SELECT * FROM users WHERE email > %{date}', date: Date.today)
# SELECT * FROM users WHERE email > '2021-02-22'

# Interpolate a list
Ensql.sql('SELECT * FROM users WHERE name IN %{(names)}', names: ['user1', 'user2'])
# SELECT * FROM users WHERE name IN ('user1', 'user2')

# Interpolate a nested VALUES list
Ensql.sql('INSERT INTO users (name, created_at) VALUES %{users( %{name}, now() )}',
  users: [{ name: "Claudia Buss" }, { name: "Lundy L'Anglais" }]
)
# INSERT INTO users VALUES ('Claudia Buss', now()), ('Lundy L''Anglais', now())

# Interpolate a SQL fragement
Ensql.sql('SELECT * FROM users ORDER BY %{!orderby}', orderby: Ensql.sql('name asc'))
# SELECT * FROM users ORDER BY name asc
```

Interpolation occurs just before the SQL is executed.

### Results

The result of an SQL query will always be a table of rows and columns, and most of the time this is what we want.
However, sometimes our queries only return a single row, column, or value. For ease-of-use, Ensql supports all 4
possible access patterns.

1. Table: an array of rows as hashes
2. Row: a hash of the first row
3. Column: an array of the first column
4. Field: an object of the first field

```ruby
Ensql.sql('SELECT * FROM users').rows # => [{ "id" => 1, …}, {"id" => 2, …}, …]
Ensql.sql('SELECT count(*) FROM users').first_field # => 100
Ensql.sql('SELECT id FROM users').first_column # => [1, 2, 3, …]
Ensql.sql('SELECT * FROM users WHERE id = %{id}', id: 1).first_row # => { "id" => 1, "email" => "test@example.com" }
```

Depending on the database and adapter, the values will be deserialised into Ruby objects.

```ruby
Ensql.sql("SELECT now() AS now, CAST('[1,2,3]' AS json)", id: 1).first_row
# => { "now" => 2021-02-23 21:17:28.105537 +1300, "json" => [1, 2, 3] }
```

Additionally, you can just return the number of rows affected, or nothing at all.

```ruby
Ensql.sql('DELETE FROM users WHERE email IS NULL').count # 10
Ensql.sql('TRUNCATE logs').run # => nil
Ensql.run('TRUNCATE logs') # same thing
```

## Things To Improve

- Interpolation syntax. I'd love to ground this in something more reasonable than ruby's custom sprintf format. Maybe we
  could relate it to the standard SQL `?` or chose an existing named bind parameter format.

- Maybe we could use type hinting like `%{param:pgarray}` to indicated how to serialise the object as a literal.

- Detecting the database and switching to a db specific adapters. This allows us to be more efficient and optimise some
  literals in a database specific format, e.g. postgres array literals.

- Handling specific connections rather than just grabbing the default.

- Establishing connections directly.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You'll
need a running postgres database. You can also run `bin/console` for an interactive prompt that will allow you to
experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the
version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielfone/ensql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
