# frozen_string_literal: true

RSpec.describe Ensql do

  before do
    require 'active_record'
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
  end

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

end
