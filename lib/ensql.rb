# frozen_string_literal: true

require_relative "ensql/version"

module Ensql
  class Error < StandardError; end

  ADAPTERS = {}

  def self.use(adapter)
    Thread.current[:ensql_adapter] = ADAPTERS[adapter] or
      raise Error, "Unknown adapter #{adapter.inspect}. Options: #{ADAPTERS.keys}"
  end

  # A shortcut for running plain SQL from our presentation layer. Safely quotes
  # and interpolates parameters via sprintf/format.
  #
  # Returns an array of hashes.
  def self.query(sql, params={})
    adapter.execute(interpolate(sql, params.transform_keys(&:to_s)))
  end

  def self.interpolate(sql, params)
    sql
      .gsub(/%{(\w+)}/) { adapter.quote params[$1] }
      .gsub(/%{(\w+)\((.+)\)}/) { params[$1].map { |attrs| sql_row(attrs, $2.split(', '))}.join(', ') } # ó_O
  end

  # We pay per line right?
  def self.sql_row(params, columns)
    "(#{params.fetch_values(*columns).map(&adapter.method(:quote)).join(', ')})"
  end

  def self.adapter
    Thread.current[:ensql_adapter] ||= ActiveRecordAdapter
  end

  module ActiveRecordAdapter
    ADAPTERS[:active_record] = self

    def self.execute(sql)
      connection.exec_query(sql).to_a
    end

    def self.quote(value)
      connection.quote(value)
    end

    # If needed, we can allow a user to supply a block to yield the connection
    # as needed
    def self.connection
      ActiveRecord::Base.connection
    end

  end

  module SequelAdapter
    ADAPTERS[:sequel] = self

    def self.execute(sql)
      connection.fetch(sql).map { |r| r.transform_keys(&:to_s) }
    end

    def self.quote(value)
      connection.literal(value)
    end

    def self.connection
      Sequel::DATABASES.first or raise Error, "No Sequel connection found in Sequel::DATABASES"
    end

  end

end
