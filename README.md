# Ensql

Ensql lets you write SQL for your application the safe and simple way. Ditch
your ORM and embrace the power and simplicity of writing plain SQL again.

## Installation

Add this gem to your Gemfile by running:

    $ bundle add ensql

Or install it manually with:

    $ gem install ensql

## Usage

By default `Ensql` looks for an existing ActiveRecord connection when a query is
made. You can also use Sequel instead.

```ruby
Ensql.use(:sequel) # Uses the first Sequel connection instead
```

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/danielfone/ensql.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
