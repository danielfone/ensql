# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in ensql.gemspec
gemspec

gem "rake", "~> 13.0"

gem "rspec", "~> 3.0"
# Ensure test coverage
gem "simplecov", "~> 0.21.2"

# Database adapters
require_relative 'lib/ensql/version'
gem "activerecord", ENV['ACTIVERECORD_VERSION'] || Ensql::ACTIVERECORD_VERSION
gem "sequel",       ENV['SEQUEL_VERSION']       || Ensql::SEQUEL_VERSION
gem "sqlite3",      ENV['SQLITE3_VERSION']      || "~> 1.4"
gem "pg",           ENV['PG_VERSION']           || "~> 1.2"

gem "yard", "~> 0.9.26"
