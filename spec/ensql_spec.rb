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
end
