# frozen_string_literal: true

require_relative "ensql/version"

module Ensql
  class Error < StandardError; end

  def self.query(sql, params={})
    params = params.transform_values(&connection.method(:quote))
    connection.exec_query(format(sql, params)).to_a
  end

  def self.connection
    ActiveRecord::Base.connection
  end

end
