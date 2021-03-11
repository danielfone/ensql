# frozen_string_literal: true

require "support/shared_adapter_examples"
require "ensql/postgres_adapter"

RSpec.describe Ensql::PostgresAdapter do
  subject(:adapter) { described_class.pool { PG.connect host: "localhost" } }

  it_behaves_like "an adapter"

  it "can round-trip ruby objects", :aggregate_failures do
    values = {
      "It's quoted" => nil,
      1100 => nil,
      1.23 => nil,
      nil => nil,
      Time.now.round(6) => :timestamp, # On linux (but not OS X), Ruby time is more precise than postgres timestamps
      Date.today => :date,
      {"a" => 1} => :json,
      [1, 2, 3] => "int[]"
    }
    values.each do |v, type|
      literal = adapter.literalize(v)
      sql = type ? "cast(#{literal} as #{type})" : literal
      expect(adapter.fetch_first_field("select #{sql}")).to eq v
    end
  end

  it "supports round-trips with custom de/encoding" do
    PG::BasicTypeRegistry.register_type(0, "macaddr", MacaddrEncoder, MacaddrDecoder)
    adapter.query_type_map[MACAddr] = MacaddrEncoder.new

    mac = MACAddr.new("08:00:2b:01:02:03")
    expect(adapter.fetch_first_field("select cast(#{adapter.literalize(mac)} as macaddr)")).to eq mac
  end
end

# Dummy MAC address struct
MACAddr = Struct.new(:string) do
  def digits
    string.tr(":", "")
  end
end

class MacaddrDecoder < PG::SimpleDecoder
  def decode(string, tuple = nil, field = nil)
    MACAddr.new(string)
  end
end

class MacaddrEncoder < PG::SimpleEncoder
  def encode(ip_addr)
    ip_addr.digits
  end
end
