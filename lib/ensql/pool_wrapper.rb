# frozen_string_literal: true

module Ensql
  # Wrap a 3rd-party connection pool with a standard interface. Connections can be checked out by {with}
  class PoolWrapper

    # Wraps a block for accessing a connection from a pool.
    #
    #     PoolWrapper.new do |client_block|
    #       my_connection_pool.with_connection(&client_block)
    #     end
    def initialize(&connection_block)
      @connection_block = connection_block
    end

    # Get a connection from our source pool
    # @yield [connection] the database-specific connection
    def with(&client_block)
      @connection_block.call(client_block)
    end
  end
end
