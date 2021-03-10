# frozen_string_literal: true

require_relative "ensql/version"
require_relative "ensql/adapter"
require_relative "ensql/sql"
require_relative "ensql/load_sql"

#
# Primary interface for loading, interpolating and executing SQL statements
# using your preferred database connection. See {.sql} for interpolation details.
#
# @example
#     # Run adhoc statements
#     Ensql.run("SET TIME ZONE 'UTC'")
#
#     # Run adhoc D/U/I statements and get the affected row count
#     Ensql.sql('DELETE FROM logs WHERE timestamp < %{expiry}', expiry: 1.month.ago).count # => 100
#
#     # Organise your SQL and fetch results as convenient Ruby primitives
#     Ensql.sql_path = 'app/sql'
#     Ensql.load_sql('customers/revenue_report', params).rows # => [{ "customer_id" => 100, "revenue" => 1000}, … ]
#
#     # Easily retrive results in alternative dimensions
#     Ensql.sql('select count(*) from users').first_field # => 100
#     Ensql.sql('select id from users').first_column # => [1, 2, 3, …]
#     Ensql.sql('select * from users where id = %{id}', id: 1).first_row # => { "id" => 1, "email" => "test@example.com" }
#
module Ensql
  class << self
    # (see SQL)
    # @return [Ensql::SQL] SQL statement
    def sql(sql, params = {})
      SQL.new(sql, params)
    end

    # Convenience method to interpolate and run the supplied SQL on the current
    # adapter.
    # @return [void]
    #
    # @example
    #   Ensql.run("DELETE FROM users WHERE id = %{id}", id: user.id)
    #   Ensql.run("ALTER TABLE test RENAME TO old_test")
    #
    def run(sql, params = {})
      SQL.new(sql, params).run
    end
  end
end
