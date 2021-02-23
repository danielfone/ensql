# frozen_string_literal: true
require 'ensql'
require 'ensql/sequel_adapter'
require 'ensql/active_record_adapter'

RSpec.describe Ensql do

  before(:context) do
    Sequel::DATABASES.clear
    Sequel.connect('sqlite:/')
  end

  before do
    Ensql.adapter = Ensql::SequelAdapter
    Ensql.run 'create table if not exists test (a, b)'
    Ensql.run 'delete from test'
  end

  it "loads, interpolates, and executes SQL" do
    attrs = [
      { 'a' => 1, 'b' => 2 },
      { 'a' => 3, 'b' => 4 },
    ]
    Ensql.sql_path = 'spec/sql'
    Ensql.load_sql(:multi_insert_test, attrs: attrs).run
    Ensql.run("insert into test (a, b) values (%{a}, %{b})", a: 5, b: 6)
    expect(Ensql.sql("select count(*) from test").first_field).to eq 3
    expect(Ensql.sql("select * from test where a > %{a}", a: 1).rows).to eq [{
      "a" => 3, "b" => 4,
    }, {
      "a" => 5, "b" => 6,
    }]
  end

  it 'can use Sequel or ActiveRecord' do
    Ensql.adapter = Ensql::SequelAdapter
    expect { Ensql.run('select * from not_a_table') }.to raise_error Sequel::DatabaseError

    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    Ensql.adapter = Ensql::ActiveRecordAdapter
    expect { Ensql.run('select * from not_a_table') }.to raise_error ActiveRecord::StatementInvalid
  end

  describe '.sql' do
    it 'instantiates a new SQL object' do
      expect(Ensql.sql('select %{a}', a: 1).to_sql).to eq 'select 1'
    end
  end

  describe '.load_sql' do
    before { Ensql.sql_path = 'spec/sql' }

    it 'interpolates into the sql at the configured path' do
      expect(Ensql.load_sql(:select_some, limit: 2).to_sql).to eq "select * from test limit 2\n"
    end

    it 'fails clearly for missing files' do
      expect { Ensql.load_sql(:missing_file) }.to raise_error including('spec/sql/missing_file.sql')
    end
  end

  describe '.run' do
    it 'executes the interpolated SQL' do
      expect {
        Ensql.run 'insert into test values (%{a}, %{b})', a: 'foo', b: 'bar'
      }.to change {
        Ensql.sql("select b from test where a = 'foo'").first_field
      }.from(nil).to('bar')
    end

    it 'returns nil' do
      expect(Ensql.run('select 1')).to eq nil
    end
  end

  describe '.adapter' do

    it 'autodetects Sequel and ActiveRecord' do
      Ensql.adapter = nil
      expect(Ensql.adapter).to eq Ensql::SequelAdapter
      hide_const 'Sequel'
      Ensql.adapter = nil
      expect(Ensql.adapter).to eq Ensql::ActiveRecordAdapter
    end

    it 'raises if autodetection fails' do
      Ensql.adapter = nil
      hide_const 'Sequel'
      hide_const 'ActiveRecord'
      expect { Ensql.adapter }.to raise_error Ensql::Error, including("Couldn't autodetect an adapter")
    end

    it 'can be manually set' do
      expect { Ensql.adapter = :foo }
        .to change { Ensql.adapter }.to :foo
    end
  end

  it "has a version number" do
    expect(Ensql::VERSION).not_to be nil
  end

  describe 'v2' do
    pending 'uses pg directly'
    pending 'streams results'
    pending 'can be configured to use bind variables'
  end

end
