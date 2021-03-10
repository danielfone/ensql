# frozen_string_literal: true

require "ensql/transaction"

RSpec.describe "Transactions" do
  let(:adapter) { spy(:adapter) }

  before { Ensql.adapter = adapter }

  describe "Ensql.transaction" do
    it "starts and commits a transaction around a block" do
      expect { |b| Ensql.transaction(&b) }.to yield_control
      expect(adapter).to have_received(:run).with("START TRANSACTION").ordered
      expect(adapter).to have_received(:run).with("COMMIT").ordered
    end

    it "returns the result of the block" do
      expect(Ensql.transaction { :foo }).to eq :foo
    end

    it "rolls back on exception" do
      expect { Ensql.transaction { raise "foo" } }.to raise_error "foo"
      expect(adapter).to have_received(:run).with("START TRANSACTION").ordered
      expect(adapter).to have_received(:run).with("ROLLBACK").ordered
    end

    it "rolls back on `:rollback`" do
      expect(Ensql.transaction { :rollback }).to eq :rollback
      expect(adapter).to have_received(:run).with("START TRANSACTION").ordered
      expect(adapter).to have_received(:run).with("ROLLBACK").ordered
    end

    it "uses the supplied SQL" do
      Ensql.transaction(start: "begin", commit: "save") {}
      expect(adapter).to have_received(:run).with("begin").ordered
      expect(adapter).to have_received(:run).with("save").ordered

      Ensql.transaction(rollback: "revert") { :rollback }
      expect(adapter).to have_received(:run).with("revert").ordered
    end
  end

  describe "Ensql.rollback!" do
    it "rolls back the transaction" do
      Ensql.transaction { Ensql.rollback! && raise("shouldn't be executed") }
      expect(adapter).to have_received(:run).with("START TRANSACTION").ordered
      expect(adapter).to have_received(:run).with("ROLLBACK").ordered
    end

    it "raises outside of a transaction" do
      expect { Ensql.rollback! }.to raise_error Ensql::Error, including("not in a transaction")
    end
  end
end
