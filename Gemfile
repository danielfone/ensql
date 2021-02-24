# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in ensql.gemspec
gemspec

group :adapters do
  require_relative 'lib/ensql/version'
  gem "activerecord", Ensql::SUPPORTED_ACTIVERECORD_VERSIONS
  gem "sequel",       Ensql::SUPPORTED_SEQUEL_VERSIONS
  gem "sqlite3",      "~> 1.4"
  gem "pg",           "~> 1.2"
  gem "sequel_pg"
end
