# frozen_string_literal: true

require_relative 'version'
require_relative 'adapter'

# Ensure our optional dependency has a compatible version
gem 'activerecord', Ensql::SUPPORTED_ACTIVERECORD_VERSIONS
require 'active_record'

module Ensql
  #
  # Implements the {Adapter} interface for ActiveRecord. Requires an
  # ActiveRecord connection to be configured and established. Uses
  # ActiveRecord::Base for the connection.
  #
  # @example
  #   require 'active_record'
  #   ActiveRecord::Base.establish_connection(adapter: 'postgresql', database: 'mydb')
  #   Ensql.adapter = Ensql::ActiveRecordAdapter
  #
  # @see SUPPORTED_ACTIVERECORD_VERSIONS
  #
  module ActiveRecordAdapter
    extend Adapter

    # @!visibility private
    def self.fetch_rows(sql)
      fetch_each_row(sql).to_a
    end

    # @!visibility private
    def self.fetch_each_row(sql, &block)
      return to_enum(:fetch_each_row, sql) unless block_given?

      result = connection.exec_query(sql)
      # AR populates `column_types` with the types of any columns that haven't
      # already been type casted by pg decoders. If present, we need to
      # deserialize them now.
      if result.column_types.any?
        result.each { |row| yield deserialize_types(row, result.column_types) }
      else
        result.each(&block)
      end
    end

    # @!visibility private
    def self.run(sql)
      connection.execute(sql)
    end

    # @!visibility private
    def self.fetch_count(sql)
      connection.exec_update(sql)
    end

    # @!visibility private
    def self.literalize(value)
      connection.quote(value)
    end

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.deserialize_types(row, column_types)
      row.each_with_object({}) { |(column, value), hash|
        hash[column] = column_types[column]&.deserialize(value) || value
      }
    end

    private_class_method :connection, :deserialize_types

  end
end
