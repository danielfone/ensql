# frozen_string_literal: true

require_relative "error"
require_relative "adapter"

module Ensql
  class << self
    # Wrap a block with a transaction. Uses the well supported
    # SQL-standard commands for controlling a transaction by default, however database
    # specific statements can be supplied. Any exceptions inside the block will
    # trigger a rollback and be reraised. Alternatively, you can call
    # {rollback!} to immediately exit the block and rollback the transaction.
    # Returns the result of the block. If the block returns `:rollback`, the
    # transaction will also be rolled back.
    #
    #     # If `do_thing1` or `do_thing2` raise an error, no statements are committed.
    #     Ensql.transaction { do_thing1; do_thing2 }
    #
    #     # If `do_thing2` is falsey, `do_thing1` is rolled back and `do_thing3` is skipped.
    #     Ensql.transaction { do_thing1; do_thing2 or Ensql.rollback!; do_thing3 }
    #
    #     # Nest transactions with savepoints.
    #     Ensql.transaction do
    #       do_thing1
    #       Ensql.transaction(start: 'SAVEPOINT my_savepoint', commit: 'RELEASE SAVEPOINT my_savepoint', rollback: 'ROLLBACK TO SAVEPOINT my_savepoint') do
    #         do_thing2
    #         do_thing3
    #       end
    #     end
    #
    #     # Use database-specific transaction semantics.
    #     Ensql.transaction(start: 'BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE') { }
    #
    # @see rollback!
    # @param start the SQL to begin the transaction.
    # @param commit the SQL to commit the transaction if successful.
    # @param rollback the SQL to rollback the transaction if an error is raised.
    def transaction(start: "START TRANSACTION", commit: "COMMIT", rollback: "ROLLBACK", &block)
      adapter.run(start)
      result = catch(:rollback, &block)
      adapter.run(result == :rollback ? rollback : commit)
      result
    # # We need to try rollback on _any_ exception. Since we reraise, rescuing this is safe.
    rescue Exception # rubocop:disable Lint/RescueException
      adapter.run(rollback)
      raise
    end

    # Immediately rollback and exit the current transaction block. See
    # {transaction}.
    def rollback!
      throw :rollback, :rollback
    rescue UncaughtThrowError
      raise Error, "not in a transaction block, can't rollback"
    end
  end
end
