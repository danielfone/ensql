# frozen_string_literal: true
require 'ensql/active_record_adapter'
require 'ensql/sequel_adapter'

RSpec.describe 'Adapters' do

  shared_examples_for "an adapter" do
    subject(:adapter) { described_class }

    before do
      adapter.run 'create temporary table if not exists ensql_adapter_test (a text, b numeric)'
      adapter.run 'truncate ensql_adapter_test'
      adapter.run 'insert into ensql_adapter_test values (1, 2), (3, 4)'
    end

    describe "#literalize(value)", :aggregate_failures do

      it 'quotes strings' do
        expect(adapter.literalize("Hi")).to eq "'Hi'"
        expect(adapter.literalize("It's quoted")).to eq "'It''s quoted'"
      end

      it 'casts non-string values' do
        expect(adapter.literalize(-12)).to eq "-12"
        expect(adapter.literalize(1.23)).to eq "1.23"
        expect(adapter.literalize(Date.new(2020))).to eq "'2020-01-01'"
        expect(adapter.literalize(true).downcase).to eq 'true'
        expect(adapter.literalize(nil)).to eq "NULL"
      end

    end

    describe '#fetch_rows(sql)' do

      it 'returns rows as an array of hashes' do
        expect(adapter.fetch_rows("select * from ensql_adapter_test")).to eq [
          { 'a' => '1', 'b' => 2 },
          { 'a' => '3', 'b' => 4 },
        ]
      end

      it 'casts values' do
        expect(adapter.fetch_rows("select cast('2021-01-01' as timestamp), cast('[1,2,3]' as json)")).to eq [
          { "json" => [1, 2, 3], "timestamp" => Time.new(2021, 1, 1) }
        ]
      end

    end

    describe "#fetch_count(sql)" do

      it 'returns the number of rows affected' do
        expect(adapter.fetch_count("update ensql_adapter_test set a = a")).to eq 2
        expect(adapter.fetch_count("select * from ensql_adapter_test")).to eq 2
      end

    end

    describe "#run(sql)" do

      it 'runs the supplied statements' do
        expect { adapter.run 'insert into ensql_adapter_test values (10,11)'}
          .to change { adapter.fetch_first_field('select count(*) from ensql_adapter_test') }.from(2).to(3)
      end

    end

    describe "#fetch_each_row(sql, &block)" do

      it 'yields each row as a hash' do
        expect { |block|
          adapter.fetch_each_row('select * from ensql_adapter_test', &block)
        }.to yield_successive_args(
          { 'a' => '1', 'b' => 2 },
          { 'a' => '3', 'b' => 4 },
        )
      end

    end

    describe "#fetch_first_row(sql)" do

      it 'returns the first row as a hash' do
        expect(adapter.fetch_first_row("select * from ensql_adapter_test")).to eq(
          'a' => '1',
          'b' => 2,
        )
      end

    end

    describe "#fetch_first_column(sql)" do

      it 'returns the first column as an array' do
        expect(adapter.fetch_first_column("select b from ensql_adapter_test")).to eq [2, 4]
      end

    end

    describe "#fetch_first_field(sql)" do

      it 'returns the first field' do
        expect(adapter.fetch_first_field("select count(*) from ensql_adapter_test")).to eq 2
      end

    end
  end

  describe Ensql::ActiveRecordAdapter do
    before(:context) { ActiveRecord::Base.establish_connection(adapter: "postgresql") }

    it_behaves_like "an adapter"
  end

  describe Ensql::SequelAdapter do
    before(:context) do
      Sequel::DATABASES.clear
      db = Sequel.connect('postgresql:/')
      db.extension(:pg_json)
    end

    it_behaves_like "an adapter"
  end

end
