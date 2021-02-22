# frozen_string_literal: true

require_relative "../ensql"

module Ensql
  #
  # Encapsulates a plain-text SQL statement and optional parameters to interpolate. Interpolation is indicated by one
  # of the four placeholder formats:
  #
  # 1. **Literal:** `%{param}`
  #    - Interpolates `param` as a quoted string or a numeric literal depending on the class.
  #    - `nil` is interpolated as `'NULL'`.
  #    - Other objects depend on the database and the adapter, but most (like `Time`) are serialised as a quoted SQL
  #      string.
  #
  # 2. **List Expansion:** `%{(param)}`
  #    - Expands an array to a list of quoted literals.
  #    - Mostly useful for `column IN (1,2)` or postgres row literals.
  #    - Empty arrays are interpolated as `(NULL)` for SQL conformance.
  #    - The parameter will be converted to an Array.
  #
  # 3. **Nested List:** `%{param(nested sql)}`
  #    - Takes an array of parameter hashes and interpolates the nested SQL for each Hash in the Array.
  #    - Raises an error if param is nil or a non-hash array.
  #    - Primary useful for SQL `VALUES ()` clauses.
  #
  # 4. **SQL Fragment:** `%{!sql_param}`
  #    - Interpolates the parameter without quoting, as a SQL fragment.
  #    - The parameter _must_ be an {Ensql::SQL} object or this will raise an error.
  #    - `nil` will not be interpolated.
  #    - Allows composition of SQL via subqueries.
  #
  # Any placeholders in the SQL must be present in the params hash or a KeyError will be raised during interpolation.
  #
  # @example
  #   # Interpolate a literal
  #   Ensql.sql('SELECT * FROM users WHERE email > %{date}', date: Date.today)
  #   # SELECT * FROM users WHERE email > '2021-02-22'
  #
  #   # Interpolate a list
  #   Ensql.sql('SELECT * FROM users WHERE name IN %{(names)}', names: ['user1', 'user2'])
  #   # SELECT * FROM users WHERE name IN ('user1', 'user2')
  #
  #   # Interpolate a nested VALUES list
  #   Ensql.sql('INSERT INTO users (name, created_at) VALUES %{users( %{name}, now() )}',
  #     users: [{ name: "Claudia Buss" }, { name: "Lundy L'Anglais" }]
  #   )
  #   # INSERT INTO users VALUES ('Claudia Buss', now()), ('Lundy L''Anglais', now())
  #
  #   # Interpolate a SQL fragement
  #   Ensql.sql('SELECT * FROM users ORDER BY %{!orderby}', orderby: Ensql.sql('name asc'))
  #   # SELECT * FROM users ORDER BY name asc
  #
  class SQL

    # @!visibility private
    def initialize(sql, params={}, name='SQL')
      @sql = sql
      @name = name.to_s
      @params = params
    end

    # (see Adapter.fetch_rows)
    def rows
      adapter.fetch_rows(to_sql)
    end

    # (see Adapter.fetch_first_row)
    def first_row
      adapter.fetch_first_row(to_sql)
    end

    # (see Adapter.fetch_first_column)
    def first_column
      adapter.fetch_first_column(to_sql)
    end

    # (see Adapter.fetch_first_field)
    def first_field
      adapter.fetch_first_field(to_sql)
    end

    # (see Adapter.fetch_count)
    def count
      adapter.fetch_count(to_sql)
    end

    # (see Adapter.run)
    def run
      adapter.run(to_sql)
      nil
    end

    # (see Adapter.fetch_each_row)
    def each_row(&block)
      adapter.fetch_each_row(to_sql, &block)
    end

    # Interpolate the params into the SQL statement.
    #
    # @raise [Ensql::Error] if any param is missing or invalid.
    # @return [String] a SQL string with parameters interpolated.
    def to_sql
      interpolate(sql, params)
    end

  private

    attr_reader :sql, :params, :name

    NESTED_LIST  = /%{(\w+)\((.+)\)}/m
    LIST         = /%{\((\w+)\)}/
    SQL_FRAGMENT = /%{!(\w+)}/
    LITERAL      = /%{(\w+)}/

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

  end
end
