# frozen_string_literal: true

require_relative "../ensql"

module Ensql
  module Adapter

    # An Adapter is expected to implement the following
    #
    # def literalize(value)
    #   raise NotImplementedError
    # end
    #
    # def fetch_rows(sql)
    #   raise NotImplementedError
    # end
    #
    # def fetch_count(sql)
    #   raise NotImplementedError
    # end
    #
    # def run(sql)
    #   fetch_rows(sql)
    # end

    # These methods can be overriden by each adapter for greater efficiency

    def fetch_each_row(sql, &block)
      fetch_rows(sql).each(&block)
    end

    def fetch_first_row(sql)
      fetch_rows(sql).first
    end

    def fetch_first_column(sql)
      fetch_rows(sql).map(&:values).map(&:first)
    end

    def fetch_first_field(sql)
      fetch_first_row(sql)&.values&.first
    end

  end
end
