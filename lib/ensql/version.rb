# frozen_string_literal: true

module Ensql
  # Gem version
  VERSION = "0.6.0"
  # Versions of activerecord compatible with the {ActiveRecordAdapter}
  SUPPORTED_ACTIVERECORD_VERSIONS = ['>= 5.0', '< 6.2'].freeze
  # Versions of sequel compatible with the {SequelAdapter}
  SUPPORTED_SEQUEL_VERSIONS = '~> 5.9'
end
