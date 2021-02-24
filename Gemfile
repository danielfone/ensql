# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in ensql.gemspec
gemspec

group :adapters do
  require_relative 'lib/ensql/version'
  gem "activerecord", Ensql::ACTIVERECORD_VERSION
  gem "sequel",       Ensql::SEQUEL_VERSION
  gem "sqlite3",      "~> 1.4"
  gem "pg",           "~> 1.2"
  gem "sequel_pg"
end
