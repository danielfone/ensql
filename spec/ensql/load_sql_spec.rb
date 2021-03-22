# frozen_string_literal: true

require "ensql/load_sql"
require "support/db"

RSpec.describe ".load_sql" do
  before do
    DB.configure_sequel_adapter
    Ensql.sql_path = "spec/sql"
  end

  it "interpolates into the sql at the configured path" do
    expect(Ensql.load_sql(:select_some, limit: 2).to_sql).to eq "select * from test limit 2\n"
  end

  it "fails clearly for missing files" do
    expect { Ensql.load_sql(:missing_file) }.to raise_error Ensql::Error, including("spec/sql/missing_file.sql")
  end
end
