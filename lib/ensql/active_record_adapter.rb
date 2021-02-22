# frozen_string_literal: true

require 'active_record'
require_relative "adapter"

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
  # @see Adapter
  #
  module ActiveRecordAdapter
    extend Adapter

    # @!visibility private
    def self.fetch_rows(sql)
      result = connection.exec_query(sql)
      result.map do |row|
        # Deserialize column types if needed
        row.each_with_object({}) do |(column, value), hash|
          hash[column] = result.column_types[column] ? result.column_types[column].deserialize(value) : value
        end
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

    private_class_method :connection

  end
end
