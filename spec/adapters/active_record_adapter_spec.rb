# frozen_string_literal: true

require "support/shared_adapter_examples"
require "ensql/active_record_adapter"

RSpec.describe Ensql::ActiveRecordAdapter do
  subject(:adapter) { described_class.new }

  before(:context) { ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "localhost") }

  it_behaves_like "an adapter"

  it "provides a raw connection pool" do
    expect { |b| Ensql::ActiveRecordAdapter.pool.with(&b) }.to yield_with_args(PG::Connection)
  end
end
