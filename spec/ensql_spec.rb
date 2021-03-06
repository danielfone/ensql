# frozen_string_literal: true

require "ensql"
require "ensql/sequel_adapter"
require "ensql/active_record_adapter"
require "ensql/postgres_adapter"

RSpec.describe Ensql do
  before(:context) do
    Sequel::DATABASES.clear
    Sequel.connect("sqlite:/")
  end

  before do
    Ensql.adapter = Ensql::SequelAdapter.new
    Ensql.run "create table if not exists test (a, b)"
    Ensql.run "delete from test"
  end

  it "loads, interpolates, and executes SQL" do
    attrs = [
      {"a" => 1, "b" => 2},
      {"a" => 3, "b" => 4}
    ]
    Ensql.sql_path = "spec/sql"
    Ensql.load_sql(:multi_insert_test, attrs: attrs).run
    Ensql.run("insert into test (a, b) values (%{a}, %{b})", a: 5, b: 6)
    expect(Ensql.sql("select count(*) from test").first_field).to eq 3
    expect(Ensql.sql("select * from test where a > %{a}", a: 1).rows).to eq [{
      "a" => 3, "b" => 4
    }, {
      "a" => 5, "b" => 6
    }]
  end

  it "can use Sequel or ActiveRecord" do
    Ensql.adapter = Ensql::SequelAdapter.new
    expect { Ensql.run("select * from not_a_table") }.to raise_error Sequel::DatabaseError

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    Ensql.adapter = Ensql::ActiveRecordAdapter.new
    expect { Ensql.run("select * from not_a_table") }.to raise_error ActiveRecord::StatementInvalid

    Ensql.adapter = Ensql::PostgresAdapter.pool { PG.connect host: "localhost" }
    expect { Ensql.run("select * from not_a_table") }.to raise_error PG::UndefinedTable
  end

  describe ".sql" do
    it "instantiates a new SQL object" do
      expect(Ensql.sql("select %{a}", a: 1).to_sql).to eq "select 1"
    end
  end

  describe ".run" do
    it "executes the interpolated SQL" do
      expect {
        Ensql.run "insert into test values (%{a}, %{b})", a: "foo", b: "bar"
      }.to change {
        Ensql.sql("select b from test where a = 'foo'").first_field
      }.from(nil).to("bar")
    end

    it "returns nil" do
      expect(Ensql.run("select 1")).to eq nil
    end
  end

  it "has a version number" do
    expect(Ensql::VERSION).not_to be nil
  end
end
