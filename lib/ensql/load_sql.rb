# frozen_string_literal: true

require_relative "sql"

module Ensql
  class << self
    # Path to search for *.sql queries in, defaults to "sql/". For example, if
    # {sql_path} is set to 'app/queries', `load_sql('users/active')` will read
    # 'app/queries/users/active.sql'.
    # @see .load_sql
    #
    # @example
    #   Ensql.sql_path = Rails.root.join('app/queries')
    #
    def sql_path
      @sql_path ||= "sql"
    end
    attr_writer :sql_path

    # Load SQL from a file within {sql_path}. This is the recommended way to
    # manage SQL in a non-trivial project. For details of how to write
    # interpolation placeholders, see {SQL}.
    #
    # @see .sql_path=
    # @return [Ensql::SQL]
    #
    # @example
    #   Ensql.load_sql('users/activity', report_params)
    #   Ensql.load_sql(:upsert_users, imported_users_attrs)
    #
    def load_sql(name, params = {})
      path = File.join(sql_path, "#{name}.sql")
      SQL.new(File.read(path), params, name)
    end
  end
end
