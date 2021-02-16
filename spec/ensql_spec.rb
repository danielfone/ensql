# frozen_string_literal: true

require 'active_record'
require 'sequel'

RSpec.describe Ensql do

  it "has a version number" do
    expect(Ensql::VERSION).not_to be nil
  end

  it "runs a query with interpolated variables" do
    result = Ensql.query("values (%{text}, %{one}), (%{text}, %{one} + 1); ", one: 1, text: "hello")
    expect(result).to eq [
      { 'column1' => 'hello', 'column2' => 1 },
      { 'column1' => 'hello', 'column2' => 2 },
    ]
  end

  it 'inserts multiple rows of values' do
    attrs = [
      { 'a' => 1, 'b' => 2 },
      { 'a' => 3, 'b' => 4 },
    ]
    Ensql.query('create table test (a, b)')
    Ensql.query("insert into test (a, b) values %{attrs(a, b)}", attrs: attrs)
    result = Ensql.query("select * from test")
    expect(result).to eq [{
      "a" => 1, "b" => 2,
    }, {
      "a" => 3, "b" => 4,
    }]
  end

  it 'can switch adapters' do
    Sequel.connect('sqlite:/')
    Ensql.use(:sequel)
    expect { Ensql.query('select * from test') }.to raise_error Sequel::DatabaseError

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    Ensql.use(:active_record)
    expect { Ensql.query('select * from test') }.to raise_error ActiveRecord::StatementInvalid
  end

  shared_examples_for "an adapter" do |adapter|
    it 'execute queries' do
      expect(adapter.execute("select 1 as one")).to eq [{"one" => 1}]
    end

    it 'quotes values', :aggregate_failures do
      expect(adapter.quote('hi')).to eq "'hi'"
    end
  end

  describe 'ActiveRecordAdapter' do
    before do
      require 'active_record'
      ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    end

    it_behaves_like "an adapter", Ensql::ActiveRecordAdapter
  end

  describe 'SequelAdapter' do
    before do
      require 'sequel'
      Sequel.connect('sqlite:/')
    end

    it_behaves_like "an adapter", Ensql::SequelAdapter
  end

end
