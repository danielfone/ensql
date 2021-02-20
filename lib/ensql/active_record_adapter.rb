# frozen_string_literal: true

require 'active_record'
require_relative "adapter"

module Ensql
  module ActiveRecordAdapter
    extend Adapter

    def self.fetch_rows(sql)
      result = connection.exec_query(sql)
      result.map do |row|
        # Deserialize column types if needed
        row.each_with_object({}) do |(column, value), hash|
          hash[column] = result.column_types[column] ? result.column_types[column].deserialize(value) : value
        end
      end
    end

    def self.run(sql)
      connection.execute(sql)
    end

    def self.fetch_count(sql)
      connection.exec_update(sql)
    end

    def self.literalize(value)
      connection.quote(value)
    end

    # If needed, we can allow a user to supply a block to yield the connection
    # as needed
    def self.connection
      ActiveRecord::Base.connection
    end

  end
end
