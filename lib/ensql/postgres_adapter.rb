# frozen_string_literal: true

require_relative 'version'
require_relative 'adapter'

gem 'pg', Ensql::SUPPORTED_PG_VERSIONS
require 'pg'
require 'connection_pool'

module Ensql
  # Wraps a pool of PG connections to implement the {Adapter} interface. The
  # adapter can use a 3rd-party pool (e.g. from ActiveRecord of Sequel) or
  # manage its own using the simple
  # [connection_pool gem](https://github.com/mperham/connection_pool).
  #
  # This adapter is much faster and offers much better PostgreSQL specific
  # parameter interpolation than the framework adapters.
  #
  # @example
  #     # Use with ActiveRecord's connection pool
  #     Ensql.adapter = Ensql::PostgresAdapter.new(Ensql::ActiveRecordAdapter.pool)
  #
  #     # Use with Sequel's connection pool
  #     DB = Sequel.connect(ENV['DATABASE_URL'])
  #     Ensql.adapter = Ensql::PostgresAdapter.new(Ensql::SequelAdapter.pool(DB))
  #
  #     # Use with our own thread-safe connection pool
  #     Ensql.adapter = Ensql::PostgresAdapter.pool { PG.connect ENV['DATABASE_URL'] }
  #     Ensql.adapter = Ensql::PostgresAdapter.pool(size: 5) { PG.connect ENV['DATABASE_URL'] }
  #
  # @see SUPPORTED_PG_VERSIONS
  #
  class PostgresAdapter
    include Adapter

    # Set up a connection pool using the supplied block to initialise connections.
    #
    #     PostgresAdapter.pool(size: 20) { PG.connect ENV['DATABASE_URL'] }
    #
    # @param pool_opts are sent straight to the ConnectionPool initializer.
    # @option pool_opts [Integer] timeout (5) number of seconds to wait for a connection if none currently available.
    # @option pool_opts [Integer] size (5) number of connections to pool.
    # @yieldreturn [PG::Connection] a new connection.
    def self.pool(**pool_opts, &connection_block)
      new ConnectionPool.new(**pool_opts, &connection_block)
    end

    # @param pool [#with] must yield a PG::Connection
    #
    def initialize(pool)
      @pool = pool
      @quoter = PG::TextEncoder::QuotedLiteral.new
      @result_type_map = @pool.with { |c| PG::BasicTypeMapForResults.new(c) }
      @query_type_map = @pool.with { |c| PG::BasicTypeMapForQueries.new(c) }
      @query_type_map[Date] = PG::TextEncoder::Date.new
    end

    def run(sql)
      execute(sql) { nil }
    end

    def literalize(value)
      case value
      when NilClass then 'NULL'
      when Numeric, TrueClass, FalseClass then value.to_s
      when String then @quoter.encode(value)
      else
        @quoter.encode(serialize(value))
      end
    end

    def fetch_count(sql)
      execute(sql, &:cmd_tuples)
    end

    def fetch_first_field(sql)
      fetch_result(sql) { |res| res.getvalue(0, 0) if res.ntuples > 0 && res.nfields > 0 }
    end

    def fetch_first_row(sql)
      fetch_result(sql) { |res| res[0] if res.ntuples > 0 }
    end

    # Return an array of nils if we don't have a column
    def fetch_first_column(sql)
      fetch_result(sql) { |res| res.nfields > 0 ? res.column_values(0) : Array.new(res.ntuples) }
    end

    def fetch_each_row(sql, &block)
      return to_enum(:fetch_each_row, sql) unless block_given?

      fetch_result(sql) { |res| res.each(&block) }
    end

    def fetch_rows(sql)
      fetch_result(sql, &:to_a)
    end

  private

    def fetch_result(sql)
      execute(sql) do |res|
        res.type_map = @result_type_map
        yield res
      end
    end

    def execute(sql, &block)
      @pool.with { |c| c.async_exec(sql, &block) }
    end

    # Use PG's built-in type mapping to serialize objects into SQL strings.
    def serialize(value)
      coder = encoder_for(value) or raise TypeError, "No SQL serializer for #{value.class}"
      coder.encode(value)
    end

    def encoder_for(value)
      coder = @query_type_map[value.class]
      # Handle the weird case where coder can be a method name
      coder.is_a?(Symbol) ? @query_type_map.send(coder, value) : coder
    end

  end
end
