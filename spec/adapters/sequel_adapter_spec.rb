# frozen_string_literal: true

require "support/shared_adapter_examples"
require "ensql/sequel_adapter"

RSpec.describe Ensql::SequelAdapter do
  subject(:adapter) { described_class.new }

  before(:context) do
    Sequel::DATABASES.clear
    @db = Sequel.connect("postgresql://localhost")
    @db.extension(:pg_json)
    @db.extension(:pg_streaming)
  end

  it_behaves_like "an adapter"

  it "provides a raw connection pool" do
    expect { |b| Ensql::SequelAdapter.pool(@db).with(&b) }.to yield_with_args(PG::Connection)
  end

  context "with single-row mode enabled" do
    around do |spec|
      @db.stream_all_queries = true
      spec.run
      @db.stream_all_queries = false
    end

    it "yields the first row much faster" do
      start = monotonic_now
      # Measure time to yield first row
      time_to_first_row = adapter.fetch_each_row("select * from generate_series(1,100000)") { break monotonic_now - start }
      # Measure time to it took to process the rest of the results
      time_to_finish = monotonic_now - start
      # Expect first row be be yieled in under half the time
      expect(time_to_first_row).to be < time_to_finish / 2.0
    end

    # https://blog.dnsimple.com/2018/03/elapsed-time-with-ruby-the-right-way/
    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
