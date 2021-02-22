# frozen_string_literal: true

module Ensql
  # Gem version
  VERSION = "0.6.0"
  # Version of the activerecord gem required to use the {ActiveRecordAdapter}
  ACTIVERECORD_VERSION = ['>= 5.0', '< 6.2'].freeze
  # Version of the sequel gem required to use the {SequelAdapter}
  SEQUEL_VERSION = '~> 5.10'
end
