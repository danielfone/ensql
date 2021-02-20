# Ensql

Ensql lets you write SQL for your application the safe and simple way. Ditch
your ORM and embrace the power and simplicity of writing plain SQL again.

Ensql allows you to write exactly the SQL you want and safely interpolate input
from the application.

    * Keep your SQL in their own files. Just like models or view templates, it makes sense to SQL organise your SQL on its own terms. Storing the queries in their own files encourages better formatted, well commented, literate SQL. It also leverages the syntax highlighting and other editor features associated with SQL syntax. Snippets of HTML scatter through .rb files is an awkward code smell, and SQL is no different.
    * Do more with your database. Having a place to organise clean and readable SQL encourages you to make the most of it. In every project I've worked on I've been able to replace useful amounts of imperative ruby logic with a declarative SQL query, improving performance and reducing the opportunity for type errors and untested branches.
    * Safely interpolate user-supplied data. Every web developer knows the risks of SQL injection. Ensql takes a fail-safe approach to interpolation, leveraging the underlying database adapter to turn ruby objects into properly quoted SQL literals. As long as user-supplied input is passed to Ensql as parameters, your queries will be safe and well-formed.
    * Use your existing database connection. Ensql works on top of ActiveRecord or Sequel so you don't need to manage a separate connection to the database.

## Installation

Add this gem to your Gemfile by running:

    $ bundle add ensql

Or install it manually with:

    $ gem install ensql

## Usage

By default `Ensql` looks for an existing ActiveRecord connection when a query is
made. You can also use Sequel instead.

```ruby
Ensql.use(:sequel) # Will use the first Sequel connection instead
Ensql.use(:active_record) # Switch back to ActiveRecord::Base
```

SQL can be supplied directly or read from a file.

```ruby
# Load SQL from a configured directory
Ensql.query_dir = 'app/queries'
Ensql.load('reports/daily_activity', organisation_id: 1, date: Date.yesterday)

# Supply SQL directly. There should NEVER be user-supplied input in the SQL
Ensql::SQL.new('SELECT * FROM users WHERE last_seen > %{date}', date: Date.yesterday)
```

There are 4 types of interpolation:

1. Literal `%{param}`
This will convert the object to a quoted string or numeric literal depending on the class.

2. List `%{(param)}`
This will convert an array to a list of quoted literals. e.g. `[1, "It's fine"]` => `(1, 'It''s fine')` The parameter will be converted to an Array. Empty arrays will be converted to `(NULL)`

3. Nested List `%{param( %{a}, timestamp %{b}, %{c} + 1, cast(%{d} as int[]) )}`
This takes a Array of parameter Hashes and interpolates the inner SQL for each Hash in the Array. This is primary useful for SQL VALUES clauses.

4. SQL Fragment `%{!sql_param}`
This will assume the parameter is a SQL fragment and interpolate the input directly without any quoting. The parameter must be an Ensql::SQL object or this will raise an error.

Identifier interpolation is not supported.

Parameters will be safely interpolated into the supplied query before the query
is executed. The results are returned as an array of hashes with strings as keys.

```ruby
Ensql.query('select %{greeting} as greeting', greeting: "hello world")
# => [{"greeting"=>"hello world"}]
```

Arrays of hashes can be interpolated as multiple rows:

```ruby
attrs = [
    { a: 1, b: 2 },
    { a: 3, b: 4 },
]
# Inserts two rows
Ensql.query("insert into my_table (a, b) values %{attrs(a, b)}", attrs: attrs)
```

## Things I Don't Like

- Interpolation syntax: I'd love to ground this in something more reasonable than
  ruby's custom sprintf format. Maybe we could relate it to the standard SQL
  `?`. Maybe we could style it a la pg bind parameters $1, but we'd need to cf
  with mysql. Maybe we could use typehinting like `%{param:array}`. Nested is ok but messy.

- Interpolation strategy: we could probably simplify and clarify the quoting vs typecasting etc

- Result accessing: there's only 5 possible ways to access results, perhaps we should support them all.
    - all results as an array of hashes e.g. `select * from users` => `[{…}]`
    - the first result as a hash e.g. `select * from users where id = %{id} limit 1` => `{…}`
    - a single column as an array of values e.g. `select id from users` => `[…]`
    - a single field e.g. `select max(id) from users` => `100`
    - the number if rows affected in a dui query e.g. `delete from users` => `100`

- Adapter switching: it can trip you up bad if you're using multiple adapters in
  your codebase. This is probably rare though. Maybe we should just document
  this and show how to set up tests.

- SQL organisation: inline strings and constants really defeat the point, even
  with HEREDOC syntax highlighting. We should probably make it easy to load
  queries from files. This gives us two ways to load SQL, string or file path.

## Roadmap

- Supply specific connections: `Ensql.use(:active_record) { Widget.connection }
- Manage connections directly: `Ensql.use(:postgres)`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielfone/ensql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
