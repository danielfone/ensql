# frozen_string_literal: true

module DB
  def self.setup_sequel(connection = "sqlite:/")
    require "sequel"
    Sequel::DATABASES.clear
    Sequel.connect(connection)
  end

  def self.setup_active_record(connection = {adapter: "sqlite3", database: ":memory:"})
    require "active_record"
    ActiveRecord::Base.establish_connection(connection)
  end

  def self.configure_sequel_adapter(connection = "sqlite:/")
    require "ensql/adapter"
    require "ensql/sequel_adapter"
    Ensql.adapter = Ensql::SequelAdapter.new(setup_sequel(connection))
  end
end
