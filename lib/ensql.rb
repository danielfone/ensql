# frozen_string_literal: true

require_relative "ensql/version"

module Ensql
  class Error < StandardError; end

  # A shortcut for running plain SQL from our presentation layer. Safely quotes
  # and interpolates parameters via sprintf/format.
  #
  # Returns an array of hashes.
  def self.query(sql, params={})

    connection.exec_query(interpolate(sql, params.transform_keys(&:to_s))).to_a
  end

  def self.interpolate(sql, params)
    sql
      .gsub(/%{(\w+)}/) { connection.quote params[$1] }
      .gsub(/%{(\w+)\((.+)\)}/) { params[$1].map { |attrs| sql_row(attrs, $2.split(', '))}.join(', ') } # ó_O
  end

  # We pay per line right?
  def self.sql_row(params, columns)
    "(#{params.fetch_values(*columns).map(&connection.method(:quote)).join(', ')})"
  end

  def self.connection
    ActiveRecord::Base.connection
  end

end
