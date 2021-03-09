#!/usr/bin/env ruby
#
# Compare operations performed using each adapter
#

ENV['TZ'] = 'UTC'

require 'benchmark/ips'

require_relative 'lib/ensql/active_record_adapter'
require_relative 'lib/ensql/sequel_adapter'
require_relative 'lib/ensql/postgres_adapter'

ActiveRecord::Base.establish_connection(adapter: "postgresql")
DB = Sequel.connect("postgresql:/")
DB.extension(:pg_json)

adapters = {
  'pg     ': Ensql::PostgresAdapter.new { PG::Connection.open },
  'ar     ': Ensql::ActiveRecordAdapter.new(ActiveRecord::Base.connection_pool),
  'seq    ': Ensql::SequelAdapter.new(DB),
  'pg-ar  ': Ensql::PostgresAdapter.new(Ensql::ActiveRecordAdapter.pool),
  'pg-seq ': Ensql::PostgresAdapter.new(Ensql::SequelAdapter.pool(DB)),
}

ADAPTER = adapters.values.first

ADAPTER.run('drop table if exists number_benchmark')
ADAPTER.run('create table number_benchmark as select generate_series(1,100) as number')

adapter_tests = {
  'literalize (String)': [:literalize, "It's quoted"],
  'literalize (Long String)': [:literalize, "It's quoted" * 1000],
  'literalize (Time)': [:literalize, Time.now],
  'literalize (Int)': [:literalize, 1234],
  'literalize (bool)': [:literalize, true],
  'run INSERT': [:run, 'insert into number_benchmark values (999)'],
  'run SET': [:run, "set time zone UTC"],
  'run SELECT': [:run, 'select generate_series(1,100)'],
  'count UPDATE': [:fetch_count, 'update number_benchmark set number = number + 1'],
  'count SELECT': [:fetch_count, 'select generate_series(1,100)'],
  'first column': [:fetch_first_column, 'select generate_series(1,100)'],
  'first column (of many)': [:fetch_first_column, 'select *, now() from generate_series(1,100) as number'],
  'first field': [:fetch_first_field, 'select 1'],
  'first field with cast': [:fetch_first_field, "select cast('2021-01-01' as timestamp)"],
  'first field (of many)': [:fetch_first_field, 'select generate_series(1,100)'],
  'first row': [:fetch_first_row, "select 1, 2, 3"],
  'first row (cast)': [:fetch_first_row, "select cast('2021-01-01' as timestamp), cast('[1,2,3]' as json)"],
  'first row (of many)': [:fetch_first_row, "select generate_series(1, 100)"],
  'rows (1)': [:fetch_rows, "select 1, 1"],
  'rows (100)': [:fetch_rows, "select 1, 1, generate_series(1, 100)"],
  'rows (100,cast)': [:fetch_rows, "select cast('2021-01-01' as timestamp), cast('[1,2,3]' as json), generate_series(1, 100)"],
  'rows (100000)': [:fetch_rows, "select 1, 1, generate_series(1, 100000)"],
}

fetch_each_row_tests = {
  'each_row (1)': [:fetch_each_row, "select 1, 1" ],
  'each_row (100)': [:fetch_each_row, "select 1, 1, generate_series(1, 100)"],
  'each_row (100,cast)': [:fetch_each_row, "select cast('2021-01-01' as timestamp), cast('[1,2,3]' as json), generate_series(1, 100)"],
  'each_row (100000)': [:fetch_each_row, "select 1, 1, generate_series(1, 100000)"],
}

# Verify results are the same
adapter_tests.each do |name, args|
  results = adapters.map { |n, a| [n, a.send(*args)] }.uniq { |n, result| result }
  next if results.count == 1

  warn "Differing results for #{name}: #{args}"
  results.each { |n, result| warn "  #{n} =>  #{result.inspect[0..500]}" }
end

# Compare times
adapter_tests.each do |test_name, args|
  puts args.map { |a| a.inspect[0..100] }.join(' ')

  Benchmark.ips(quiet: true) do |x|
    x.config(stats: :bootstrap, confidence: 95, warmup: 0.2, time: 0.5)

    adapters.each do |name, adapter|
      x.report("#{test_name} - #{name}") { adapter.send(*args) }
    end

    x.compare!
  end
end

fetch_each_row_tests.each do |test_name, args|
  Benchmark.ips(quiet: true) do |x|
    x.config(stats: :bootstrap, confidence: 95, warmup: 0.2, time: 0.5)

    adapters.each do |name, adapter|
      x.report("#{test_name} - #{name}") { adapter.send(*args) { |r| r } }
    end

    x.compare!
  end
end

ADAPTER.run('drop table number_benchmark')
