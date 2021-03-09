# frozen_string_literal: true
require 'ensql/adapter'
require 'sequel'
require 'active_record'

RSpec.describe 'Ensql.adapter' do

  before(:context) do
    Sequel::DATABASES.clear
    Sequel.connect('sqlite:/')
  end

  it 'autodetects Sequel and ActiveRecord' do
    Ensql.adapter = nil
    expect(Ensql.adapter).to be_a Ensql::SequelAdapter
    hide_const 'Sequel'
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
    expect { Ensql.adapter = :foo }
      .to change { Ensql.adapter }.to :foo
  end

  it 'warns if using deprecated adapters' do
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

end
