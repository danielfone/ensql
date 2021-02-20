# frozen_string_literal: true

require_relative "../ensql"

module Ensql
  class SQL

    def initialize(sql, params={}, name='SQL')
      @sql = sql
      @name = name
      @params = params
    end

    def rows
      adapter.fetch_rows(to_sql)
    end

    def first_row
      adapter.fetch_first_row(to_sql)
    end

    def first_column
      adapter.fetch_first_column(to_sql)
    end

    def first_field
      adapter.fetch_first_field(to_sql)
    end

    # Execute the query and return the number of rows affected, useful for
    # DELETE, UPDATE, INSERT, etc.
    def count
      adapter.fetch_count(to_sql)
    end

    # Run a query without worrying about the result
    def run
      adapter.run(to_sql)
      nil
    end

    def each_row(&block)
      adapter.fetch_each_row(to_sql, &block)
    end

    def to_sql
      interpolate(sql, params)
    end

  private

    attr_reader :sql, :params, :name

    NESTED_LIST  = /%{(\w+)\((.+)\)}/m
    LIST         = /%{\((\w+)\)}/
    SQL_FRAGMENT = /%{!(\w+)}/
    # LITERAL      = /%{([\w]+)(:(\w+))?}/
    LITERAL      = /%{(\w+)}/

    # Want to interpolate a number of things
    # - literals: this can be typecast and escaped as needed. dumb => to_s.quote
    # - values lists
    # - subqueries
    # - expression lists eg IN (1,2,3)
    def interpolate(sql, params)
      params = params.transform_keys(&:to_s)
      sql
        .gsub(NESTED_LIST) { interpolate_nested_list params.fetch($1), $2 }
        .gsub(LIST) { interpolate_list params.fetch($1) }
        .gsub(SQL_FRAGMENT) { interpolate_sql params.fetch($1) }
        .gsub(LITERAL) { literalize params.fetch($1) }
    rescue => e
      raise Error, "failed interpolating `#{$1}` into #{name}: #{e}"
    end

    def interpolate_nested_list(array, nested_sql)
      raise Error, "array must not be empty" if Array(array).empty?

      Array(array)
        .map { |attrs| interpolate(nested_sql, Hash(attrs)) }
        .map { |sql| "(#{sql})" }
        .join(', ')
    end

    def interpolate_list(array)
      return '(NULL)' if Array(array).empty?

      '(' + Array(array).map { |v| literalize v }.join(', ') + ')'
    end

    def interpolate_sql(sql)
      return if sql.nil?

      raise "SQL fragment interpolation requires #{self.class}, got #{sql.class}" unless sql.is_a?(self.class)

      sql.to_sql
    end

    def literalize(value)
      adapter.literalize value
    rescue => e
      raise "error serialising #{value.class} into a SQL literal: #{e}"
    end

    def adapter
      Ensql.adapter
    end

    # Serialize a ruby object into a string suitable for interpolation into SQL
    # This needs to be extensible, but not sure if I like class-based
    # def literalize(value, name, type=nil)
    #   adapter.literalize type ? serialize(type, value) : value
    # rescue => e
    #   raise "Error quoting #{value.class} for #{name}: #{e}"
    # end

    # def serialize(type, value)
    #   Ensql.serializer.fetch(type.to_sym).call(value, adapter)
    # rescue => e
    #   raise "Couldn't serialize #{value.inspect} as #{type.type}: #{e}"
    # end
  end
end
