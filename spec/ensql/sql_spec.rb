# frozen_string_literal: true
require 'ensql/sequel_adapter'
require 'ensql/sql'

RSpec.describe Ensql::SQL do

  before(:context) do
    Sequel::DATABASES.clear
    db = Sequel.connect('sqlite:/')
    Ensql.adapter = Ensql::SequelAdapter.new(db)
    Ensql.run 'create table test (a, b)'
  end

  context 'with SQL values (1, 2), (3, 4)' do
    subject(:sql) { described_class.new('values %{a}, %{b}', a: [1, 2], b: [3, 4]) }

    describe '#rows' do
      specify { expect(sql.rows).to eq [{ "column1" => 1, "column2" => 2 }, { "column1" => 3, "column2" => 4 }] }
    end

    describe '#first_row' do
      specify { expect(sql.first_row).to eq "column1" => 1, "column2" => 2 }
    end

    describe '#first_column' do
      specify { expect(sql.first_column).to eq [1, 3] }
    end

    describe '#first_field' do
      specify { expect(sql.first_field).to eq 1 }
    end

    describe '#each_row(&block)' do
      specify {
        expect { |b| sql.each_row(&b) }
          .to yield_successive_args({ "column1" => 1, "column2" => 2 }, { "column1" => 3, "column2" => 4 })
      }
    end
  end

  context 'inserting two rows' do
    subject(:sql) { described_class.new('insert into test values %{a}, %{b}', a: [1, 2], b: [3, 4]) }

    before { Ensql.run 'delete from test' }

    describe '#count' do
      specify { expect(sql.count).to eq 2 }
    end

    describe '#run' do
      let(:count_sql) { Ensql.sql('select count(*) from test') }
      specify { expect { sql.run }.to change { count_sql.first_field }.from(0).to(2) }
      specify { expect(sql.run).to be nil }
    end

  end

  describe '#to_sql' do

    it 'raises on missing parameters' do
      expect { interpolate('select %{a}', b: 1) }
        .to raise_error Ensql::Error, including('key not found: "a"')
    end

    it 'describes interpolation failures' do
      expect { interpolate("select %{a}, %{b}", a: Object.new, b: 'b') }
        .to raise_error Ensql::Error, matching('`a`').and(matching('error serialising Object into a SQL literal'))
    end

    describe '%{parameter} interpolation' do

      it 'interpolates SQL literals' do
        params = { string: "It's quoted", numeric: 1.2, nil: nil }
        expect(interpolate('select %{string}, %{numeric}, %{nil}', params))
          .to eq "select 'It''s quoted', 1.2, NULL"
      end

    end

    describe '%{(array)} expansion' do

      it 'expands an array into quoted literals' do
        expect(interpolate('select %{(array)}', array: ["'string'", 1.2, nil]))
          .to eq "select ('''string''', 1.2, NULL)"
      end

      it 'wraps non-array values' do
        expect(interpolate('select %{(string)}', string: 'test'))
          .to eq "select ('test')"
      end

      it 'expands empty arrays to (NULL)' do
        expect(interpolate('select %{(array)}', array: []))
          .to eq "select (NULL)"
      end

    end

    describe '%{nested(%{list})} interpolation' do

      it 'interpolates each hash' do
        expect(interpolate('values %{attrs( %{a} + 1, %{b} )}', attrs: [{ a: 1, b: 2 }, { a: 3, b: 4 }]))
          .to eq 'values ( 1 + 1, 2 ), ( 3 + 1, 4 )'
      end

      it 'fails on blank parameters' do
        expect { interpolate('values %{attrs( %{a} + 1, %{b} )}', attrs: nil) }
          .to raise_error Ensql::Error, matching("`attrs`").and(matching('array must not be empty'))
      end

      it 'fails with a non-hash params' do
        expect { interpolate('values %{attrs( %{a} + 1, %{b} )}', attrs: 'string') }
          .to raise_error Ensql::Error, matching("`attrs`").and(matching("can't convert String into Hash"))
      end

    end

    describe '%{!fragment} interpolation' do

      it 'interpolates without quoting' do
        expect(interpolate('select * from test %{!order}', order: Ensql.sql('order by a')))
          .to eq 'select * from test order by a'
      end

      it "doesn't interpolate nil" do
        expect(interpolate('select * from test %{!order}', order: nil))
          .to eq 'select * from test '
      end

      it "only interpolates other instances of self" do
        expect { interpolate('select * from test %{!order}', order: 'order by a') }
          .to raise_error Ensql::Error, including('`order`').and(matching('fragment interpolation requires Ensql::SQL, got String'))
      end

    end

  end

  def interpolate(sql, params)
    Ensql::SQL.new(sql, params).to_sql
  end

end
