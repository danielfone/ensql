# frozen_string_literal: true

require 'sequel'
require_relative "../ensql"
require_relative "adapter"

module Ensql
  module SequelAdapter
    extend Adapter

    def self.fetch_rows(sql)
      db.fetch(sql).map { |r| r.transform_keys(&:to_s) }
    end

    def self.fetch_count(sql)
      db.execute_dui(sql)
    end

    def self.run(sql)
      db << sql
    end

    def self.literalize(value)
      db.literal(value)
    end

    def self.db
      Sequel::DATABASES.first or raise Error, "No Sequel connection found in Sequel::DATABASES"
    end
  end
end
