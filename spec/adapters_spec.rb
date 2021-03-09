# frozen_string_literal: true
require 'ensql/active_record_adapter'
require 'ensql/sequel_adapter'
require 'ensql/postgres_adapter'

RSpec.describe 'Adapters' do

  shared_examples_for "an adapter" do

    before do
      adapter.run 'create temporary table if not exists ensql_adapter_test (a text, b int)'
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
        expect(adapter.literalize(true)).to eq('true').or eq('TRUE').or eq("'t'")
        expect(adapter.literalize(nil)).to eq "NULL"
      end

      it 'raises for unsupported objects' do
        expect { adapter.literalize(Object.new) }
          .to raise_error(/can't quote Object|can't express #<Object|No SQL serializer for Object/)
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

      it 'returns empty results' do
        expect(adapter.fetch_rows("select where 1=1")).to eq [{}]
        expect(adapter.fetch_rows("select where 1=0")).to eq []
      end

      it 'raises on invalid queries', :aggregate_failures do
        expect { adapter.fetch_rows("foo") }.to raise_original_error(PG::SyntaxError)
        expect { adapter.fetch_rows("select * from missing_table") }.to raise_original_error(PG::UndefinedTable)
      end

    end

    describe "#fetch_count(sql)" do

      it 'returns the number of rows affected' do
        expect(adapter.fetch_count("update ensql_adapter_test set a = a")).to eq 2
        expect(adapter.fetch_count("select * from ensql_adapter_test")).to eq 2
      end

      it 'raises on invalid queries', :aggregate_failures do
        expect { adapter.fetch_count("foo") }.to raise_original_error(PG::SyntaxError)
        expect { adapter.fetch_count("select * from missing_table") }.to raise_original_error(PG::UndefinedTable)
      end

      it 'returns counts for empty results' do
        expect(adapter.fetch_count("select where 1=1")).to eq 1
        expect(adapter.fetch_count("select where 1=0")).to eq 0
      end

    end

    describe "#run(sql)" do

      it 'runs the supplied statements' do
        expect { adapter.run 'insert into ensql_adapter_test values (10,11)'}
          .to change { adapter.fetch_first_field('select count(*) from ensql_adapter_test') }.from(2).to(3)
      end

      it 'raises on invalid queries', :aggregate_failures do
        expect { adapter.fetch_count("foo") }.to raise_original_error(PG::SyntaxError)
        expect { adapter.fetch_count("select * from missing_table") }.to raise_original_error(PG::UndefinedTable)
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

      it 'yields empty results' do
        expect { |b| adapter.fetch_each_row("select where 1=1", &b) }.to yield_with_args({})
        expect { |b| adapter.fetch_each_row("select where 1=0", &b) }.not_to yield_control
      end

      it 'raises on invalid queries', :aggregate_failures do
        expect { adapter.fetch_count("foo") }.to raise_original_error(PG::SyntaxError)
        expect { adapter.fetch_count("select * from missing_table") }.to raise_original_error(PG::UndefinedTable)
      end

      it 'returns an enum if no block is supplied' do
        expect(adapter.fetch_each_row('select * from ensql_adapter_test')).to be_a Enumerator
      end

    end

    describe "#fetch_first_row(sql)" do

      it 'returns the first row as a hash' do
        expect(adapter.fetch_first_row("select * from ensql_adapter_test")).to eq(
          'a' => '1',
          'b' => 2,
        )
      end

      it 'returns blankly for empty results' do
        expect(adapter.fetch_first_row("select where 1=1")).to eq({})
        expect(adapter.fetch_first_row("select where 1=0")).to eq nil
      end

    end

    describe "#fetch_first_column(sql)" do

      it 'returns the first column as an array' do
        expect(adapter.fetch_first_column("select b from ensql_adapter_test")).to eq [2, 4]
      end

      it 'returns blankly for empty results' do
        expect(adapter.fetch_first_column("select where 1=1")).to eq [nil]
        expect(adapter.fetch_first_column("select where 1=0")).to eq []
      end

    end

    describe "#fetch_first_field(sql)" do

      it 'returns the first field' do
        expect(adapter.fetch_first_field("select count(*) from ensql_adapter_test")).to eq 2
      end

      it 'returns nil for empty results', :aggregate_failures do
        expect(adapter.fetch_first_field("select where 1=1")).to eq nil
        expect(adapter.fetch_first_field("select where 1=0")).to eq nil
      end

    end
  end

  describe Ensql::ActiveRecordAdapter do
    subject(:adapter) { described_class.new }

    before(:context) { ActiveRecord::Base.establish_connection(adapter: "postgresql", host: "localhost") }

    it_behaves_like "an adapter"

    it 'provides a raw connection pool' do
      expect { |b| Ensql::ActiveRecordAdapter.pool.with(&b) }.to yield_with_args(PG::Connection)
    end
  end

  describe Ensql::SequelAdapter do
    subject(:adapter) { described_class.new }

    before(:context) do
      Sequel::DATABASES.clear
      DB = Sequel.connect('postgresql://localhost')
      DB.extension(:pg_json)
      DB.extension(:pg_streaming)
    end

    it_behaves_like "an adapter"

    it 'provides a raw connection pool' do
      expect { |b| Ensql::SequelAdapter.pool(DB).with(&b) }.to yield_with_args(PG::Connection)
    end

    context 'with single-row mode enabled' do
      around do |spec|
        DB.stream_all_queries = true
        spec.run
        DB.stream_all_queries = false
      end

      it 'yields the first row much faster' do
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

  describe Ensql::PostgresAdapter do

    it_behaves_like "an adapter" do
      subject(:adapter) { described_class.pool { PG.connect host: 'localhost' } }

      it 'can round-trip ruby objects', :aggregate_failures do
        values = {
          "It's quoted" => nil,
          1100 => nil,
          1.23 => nil,
          nil => nil,
          Time.now.round(6) => :timestamp, # On linux (but not OS X), Ruby time is more precise than postgres timestamps
          Date.today => :date,
          { 'a' => 1 } => :json,
          [1, 2, 3] => 'int[]',
        }
        values.each do |v, type|
          literal = adapter.literalize(v)
          sql = type ? "cast(#{literal} as #{type})" : literal
          expect(adapter.fetch_first_field("select #{sql}")).to eq v
        end
      end
    end

  end

  # Matcher for an error class or cause
  def raise_original_error(klass)
    raise_error { |e| expect([e, e.cause]).to include klass }
  end

end
