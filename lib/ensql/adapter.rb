# frozen_string_literal: true

require_relative 'error'

module Ensql

  class << self
    # Get the current connection adapter. If not specified, it will try to
    # autoload an adapter based on the availability of Sequel or ActiveRecord,
    # in that order.
    #
    # @example
    #     require 'sequel'
    #     Ensql.adapter # => Ensql::SequelAdapter.new
    #     Ensql.adapter = Ensql::ActiveRecordAdapter.new # override adapter
    #     Ensql.adapter = my_tsql_adapter # supply your own adapter
    #
    def adapter
      Thread.current[:ensql_adapter] || Thread.main[:ensql_adapter] ||= autoload_adapter
    end

    # Set the connection adapter to use. Must implement the interface defined in
    # {Ensql::Adapter}. This uses a thread-local variable so adapters can be
    # switched safely in a multi-threaded web server.
    def adapter=(adapter)
      if adapter.is_a?(Module) && (adapter.name == 'Ensql::SequelAdapter' || adapter.name == 'Ensql::ActiveRecordAdapter')
        warn "Using `#{adapter}` as an adapter is deprecated, use `#{adapter}.new`.", uplevel: 1
      end

      Thread.current[:ensql_adapter] = adapter
    end

  private

    def autoload_adapter
      if defined? Sequel
        require_relative 'sequel_adapter'
        SequelAdapter.new
      elsif defined? ActiveRecord
        require_relative 'active_record_adapter'
        ActiveRecordAdapter.new
      else
        raise Error, "Couldn't autodetect an adapter, please specify manually."
      end
    end

  end

  #
  # @abstract Do not use this module directly.
  #
  # A common interface for executing SQL statements and retrieving (or not)
  # their results. Some methods have predefined implementations for convenience
  # that can be improved in the adapters.
  #
  module Adapter

    # @!group 1. Interface Methods

    # @!method literalize(value)
    #
    # Convert a Ruby object into a string that can be safely interpolated into
    # an SQL statement. Strings will be correctly quoted. The precise result
    # will depend on the adapter and the underlying database driver, but most
    # RDBMs have limited ways to express literals.
    #
    # @return [String] a properly quoted SQL literal
    #
    # @see https://www.postgresql.org/docs/13/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS
    # @see https://dev.mysql.com/doc/refman/8.0/en/literals.html
    # @see https://sqlite.org/lang_expr.html#literal_values_constants_
    #
    # @example
    #   literalize("It's quoted") # => "'It''s quoted'"
    #   literalize(1.23) # => "1.23"
    #   literalize(true) # => "1"
    #   literalize(nil) # => "NULL"
    #   literalize(Time.now) # => "'2021-02-22 23:44:28.942947+1300'"

    # @!method fetch_rows(sql)
    #
    # Execute the query and return an array of rows represented by { column => field }
    # hashes. Fields should be deserialised depending on the column type.
    #
    # @return [Array<Hash>] rows as hashes keyed by column name

    # @!method fetch_each_row(sql)
    #
    # Execute the query and yield each resulting row. This should provide a more
    # efficient method of iterating through large datasets.
    #
    # @yield <Hash> row

    # @!method fetch_count(sql)
    #
    # Execute the statement and return the number of rows affected. Typically
    # used for DELETE, UPDATE, INSERT, but will work with SELECT on some
    # databases.
    #
    # @return <Integer> the number of rows affected by the statement

    # @!method run(sql)
    #
    # Execute the statement on the database without returning any result. This
    # can avoid the overhead of other fetch_* methods.
    #
    # @return <void>

    # @!group 2. Predefined Methods


    # Execute the query and return only the first row of the result.
    # @return <Hash>
    def fetch_first_row(sql)
      fetch_each_row(sql).first
    end

    # Execute the query and return only the first column of the result.
    # @return <Array>
    def fetch_first_column(sql)
      fetch_rows(sql).map(&:values).map(&:first)
    end

    # Execute the query and return only the first field of the first row of the result.
    def fetch_first_field(sql)
      fetch_first_row(sql)&.values&.first
    end

  end
end
