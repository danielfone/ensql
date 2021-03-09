# frozen_string_literal: true
require 'ensql/adapter'

RSpec.describe 'Ensql.adapter' do

  it 'autodetects Sequel and ActiveRecord' do
    setup_sequel
    Ensql.adapter = nil
    expect(Ensql.adapter).to be_a Ensql::SequelAdapter
    hide_const 'Sequel'

    setup_active_record
    Ensql.adapter = nil
    expect(Ensql.adapter).to be_a Ensql::ActiveRecordAdapter
  end

  it 'raises if autodetection fails' do
    Ensql.adapter = nil
    hide_const 'Sequel'
    hide_const 'ActiveRecord'
    expect { Ensql.adapter }.to raise_error Ensql::Error, including("Couldn't autodetect an adapter")
  end

  it 'can be manually set' do
    Ensql.adapter = :foo
    expect { Ensql.adapter = :bar }
      .to change { Ensql.adapter }.from(:foo).to(:bar)
  end

  it 'warns if using deprecated adapters' do
    require 'ensql/active_record_adapter'
    require 'ensql/sequel_adapter'
    expect { Ensql.adapter = Ensql::ActiveRecordAdapter }.to output(/deprecated/).to_stderr
    expect { Ensql.adapter = Ensql::SequelAdapter }.to output(/deprecated/).to_stderr
  end

  describe 'thread-safety' do

    it 'is autodetected in all threads' do
      Ensql.adapter = nil
      expect(Ensql.adapter).to eq Thread.new { Ensql.adapter }.join.value
    end

    it 'is shared from main thread' do
      Ensql.adapter = :foo
      Thread.new { expect(Ensql.adapter).to eq :foo }
    end

    it 'is isolated between child threads' do
      Ensql.adapter = :foo
      Thread.new {
        Ensql.adapter = :bar
        expect(Ensql.adapter).to eq :bar
      }.join.value
      expect(Ensql.adapter).to eq :foo
    end

  end

  def setup_sequel(connection_string='sqlite:/')
    require 'sequel'
    Sequel::DATABASES.clear
    Sequel.connect(connection_string)
  end

  def setup_active_record(opts = { adapter: "sqlite3", database: ":memory:" })
    require 'active_record'
    ActiveRecord::Base.establish_connection(opts)
  end

end
