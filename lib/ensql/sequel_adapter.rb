# frozen_string_literal: true

require 'sequel'
require_relative "../ensql"
require_relative "adapter"

module Ensql
  #
  # Implements the {Adapter} interface for Sequel. Requires a Sequel connection to
  # be established. Uses the first connection found in Sequel::DATABASES. You
  # may want to utilize the relevant extensions to make the most of the
  # deserialization.
  #
  # @example
  #   require 'sequel'
  #   DB = Sequel.connect('postgres://localhost/mydb')
  #   DB.extend(:pg_json)
  #   Ensql.adapter = Ensql::SequelAdapter
  #
  # @see Adapter
  #
  module SequelAdapter
    extend Adapter

    # @!visibility private
    def self.fetch_rows(sql)
      db.fetch(sql).map { |r| r.transform_keys(&:to_s) }
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
