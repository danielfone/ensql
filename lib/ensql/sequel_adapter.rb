# frozen_string_literal: true

require_relative 'version'
require_relative 'adapter'

# Ensure our optional dependency has a compatible version
gem 'sequel', Ensql::SUPPORTED_SEQUEL_VERSIONS
require 'sequel'

module Ensql
  #
  # Implements the {Adapter} interface for Sequel. Requires a Sequel connection
  # to be established. Uses the first connection found in Sequel::DATABASES. You
  # may want to utilize the relevant extensions to make the most of
  # deserialization and other database features.
  #
  #     require 'sequel'
  #     DB = Sequel.connect('postgres://localhost/mydb')
  #     DB.extend(:pg_json)
  #     Ensql.adapter = Ensql::SequelAdapter
  #
  # To stream rows, configure streaming on the connection and use
  # {SQL.each_row}
  #
  #      DB = Sequel.connect('postgresql:/')
  #      DB.extension(:pg_streaming)
  #      DB.stream_all_queries = true
  #      Ensql.sql("select * from large_table").each_row do  |row|
  #        # This now yields each row in single-row mode.
  #        # The connection cannot be used for other queries while this is streaming.
  #      end
  #
  # @see SUPPORTED_SEQUEL_VERSIONS
  #
  module SequelAdapter
    extend Adapter

    # @!visibility private
    def self.fetch_rows(sql)
      fetch_each_row(sql).to_a
    end

    # @!visibility private
    def self.fetch_each_row(sql)
      return to_enum(:fetch_each_row, sql) unless block_given?

      db.fetch(sql) { |r| yield r.transform_keys(&:to_s) }
    end

    # @!visibility private
    def self.fetch_count(sql)
      db.execute_dui(sql)
    end

    # @!visibility private
    def self.run(sql)
      db << sql
    end

    # @!visibility private
    def self.literalize(value)
      db.literal(value)
    end

    def self.db
      Sequel::DATABASES.first or raise Error, "no connection found in Sequel::DATABASES"
    end

    private_class_method :db

  end
end
