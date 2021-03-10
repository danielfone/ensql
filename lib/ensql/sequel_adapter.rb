# frozen_string_literal: true

require_relative "version"
require_relative "adapter"
require_relative "pool_wrapper"
require_relative "error"

# Ensure our optional dependency has a compatible version
gem "sequel", Ensql::SUPPORTED_SEQUEL_VERSIONS
require "sequel"

module Ensql
  #
  # Wraps a Sequel::Database to implement the {Adapter} interface for Sequel.
  # You may want to utilize the relevant Sequel extensions to make the most of
  # database-specific deserialization and other features.  By default, uses the
  # first database in Sequel::Databases. Other databases can be passed to the
  # constructor.
  #
  #     require 'sequel'
  #     DB = Sequel.connect('postgres://localhost/mydb')
  #     DB.extend(:pg_json)
  #     Ensql.adapter = Ensql::SequelAdapter.new(DB)
  #
  # To stream rows, configure streaming on the connection and use
  # {SQL.each_row}
  #
  #      DB = Sequel.connect('postgresql:/')
  #      DB.extension(:pg_streaming)
  #      DB.stream_all_queries = true
  #      Ensql.adapter = Ensql::SequelAdapter.new(DB)
  #      Ensql.sql("select * from large_table").each_row do  |row|
  #        # This now yields each row in single-row mode.
  #        # The connection cannot be used for other queries while this is streaming.
  #      end
  #
  # @see SUPPORTED_SEQUEL_VERSIONS
  #
  class SequelAdapter
    include Adapter

    # Support deprecated class method interface
    class << self
      require "forwardable"
      extend Forwardable

      delegate [:literalize, :run, :fetch_count, :fetch_each_row, :fetch_rows, :fetch_first_column, :fetch_first_field, :fetch_first_row] => :new
    end

    # Wrap the raw connections from a Sequel::Database connection pool. This
    # allows us to safely checkout the underlying database connection for use in
    # a database specific adapter.
    #
    #     Ensql.adapter = MySqliteAdapter.new(SequelAdapter.pool)
    #
    # @param db [Sequel::Database]
    # @return [PoolWrapper] a pool adapter for raw connections
    def self.pool(db)
      PoolWrapper.new do |client_block|
        db.pool.hold(&client_block)
      end
    end

    # @param db [Sequel::Database]
    def initialize(db = first_configured_database)
      @db = db
    end

    # @visibility private
    def fetch_rows(sql)
      fetch_each_row(sql).to_a
    end

    # @visibility private
    def fetch_each_row(sql)
      return to_enum(:fetch_each_row, sql) unless block_given?

      db.fetch(sql) { |r| yield r.transform_keys(&:to_s) }
    end

    # @visibility private
    def fetch_count(sql)
      db.execute_dui(sql)
    end

    # @visibility private
    def run(sql)
      db << sql
      nil
    end

    # @visibility private
    def literalize(value)
      db.literal(value)
    end

    private

    attr_reader :db

    def first_configured_database
      Sequel::DATABASES.first || raise(Error, "no database found in Sequel::DATABASES")
    end
  end
end
