# frozen_string_literal: true

require_relative "ensql/version"
require_relative "ensql/sql"

module Ensql
  class Error < StandardError; end

  class << self
    # Convenience method for wrapping a plain SQL string. A useful shortcut for
    # SQL framement interpolation when coupled with `%{!param}` e.g.
    # `Ensql.load('active_customers', order: Ensql.sql('age desc')`
    #
    # Returns a Ensql::SQL object.
    def sql(sql, params={})
      SQL.new(sql, params)
    end

    # Set the path to search for *.sql queries in, defaults to ./sql/
    attr_writer :sql_path
    def sql_path
      @sql_path ||= File.join(Dir.pwd, 'sql')
    end

    # Load SQL from a path within the configured queries path. For example, if
    # sql_dir is set to './sql/', `load('users/active')`` will read from
    # './sql/users/active.sql'
    #
    # Returns a Ensql::SQL object
    def load_sql(name, params={})
      path = File.join(sql_path, "#{name}.sql")
      SQL.new(File.read(path), params, name)
    end

    # Convenience method
    def run(sql, params={})
      SQL.new(sql, params).run
    end

    # Configure the connection adapter being used. The adapter must be required first.
    attr_writer :adapter

    def adapter
      @adapter ||= autoload_adapter
    end

  private

    def autoload_adapter
      if defined? Sequel
        require_relative 'ensql/sequel_adapter'
        SequelAdapter
      elsif defined? ActiveRecord
        require_relative 'ensql/active_record_adapter'
        ActiveRecordAdapter
      else
        raise Error, "Couldn't autodetect an adapter, please specify manually."
      end
    end

  end
end
