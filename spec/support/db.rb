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
end
