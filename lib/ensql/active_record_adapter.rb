# frozen_string_literal: true

require_relative "version"
require_relative "adapter"
require_relative "pool_wrapper"

# Ensure our optional dependency has a compatible version
gem "activerecord", Ensql::SUPPORTED_ACTIVERECORD_VERSIONS
require "active_record"

module Ensql
  #
  # Wraps an ActiveRecord connection pool to implement the {Adapter} interface
  # for ActiveRecord. Requires an ActiveRecord connection to be configured and
  # established. By default, uses the connection pool on ActiveRecord::Base.
  # Other pools can be passed to the constructor.
  #
  # @example
  #   require 'active_record'
  #   ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'mydb')
  #   Ensql.adapter = Ensql::ActiveRecordAdapter.new
  #   # Use database configuration for the Widget model instead
  #   Ensql.adapter = Ensql::ActiveRecordAdapter.new(Widget)
  #
  # @see SUPPORTED_ACTIVERECORD_VERSIONS
  #
  class ActiveRecordAdapter
    include Adapter

    # Wrap the raw connections from an Active Record connection pool. This
    # allows us to safely checkout the underlying database connection for use in
    # a database specific adapter.
    #
    #     Ensql.adapter = MySqliteAdapter.new(ActiveRecordAdapter.pool)
    #
    # @param base [Class] an ActiveRecord class to source connections from
    # @return [PoolWrapper] a pool adapter for raw connections
    def self.pool(base = ActiveRecord::Base)
      PoolWrapper.new do |client_block|
        base.connection_pool.with_connection { |connection| client_block.call connection.raw_connection }
      end
    end

    # Support deprecated class method interface
    class << self
      require "forwardable"
      extend Forwardable

      delegate [:literalize, :run, :fetch_count, :fetch_each_row, :fetch_rows, :fetch_first_column, :fetch_first_field, :fetch_first_row] => :new
    end

    # @param base [Class] an ActiveRecord class to source connections from
    def initialize(base = ActiveRecord::Base)
      @base = base
    end

    # @visibility private
    def fetch_rows(sql)
      fetch_each_row(sql).to_a
    end

    # @visibility private
    def fetch_each_row(sql, &block)
      return to_enum(:fetch_each_row, sql) unless block

      result = with_connection { |c| c.exec_query(sql) }
      # AR populates `column_types` with the types of any columns that haven't
      # already been type casted by pg decoders. If present, we need to
      # deserialize them now.
      if result.column_types.any?
        result.each { |row| yield deserialize_types(row, result.column_types) }
      else
        result.each(&block)
      end
    end

    # @visibility private
    def run(sql)
      with_connection { |c| c.execute(sql) }
      nil
    end

    # @visibility private
    def fetch_count(sql)
      with_connection { |c| c.exec_update(sql) }
    end

    # @visibility private
    def literalize(value)
      with_connection { |c| c.quote(value) }
    end

    private

    def with_connection(&block)
      @base.connection_pool.with_connection(&block)
    end

    def deserialize_types(row, column_types)
      column_types.each { |column, type| row[column] = type.deserialize(row[column]) }
      row
    end
  end
end
