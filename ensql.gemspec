# frozen_string_literal: true

require_relative "lib/ensql/version"

Gem::Specification.new do |spec|
  spec.name = "ensql"
  spec.version = Ensql::VERSION
  spec.authors = ["Daniel Fone"]
  spec.email = ["daniel@fone.net.nz"]

  spec.summary = "Write SQL the safe and simple way"
  spec.description = "Escape your ORM and embrace the power and simplicity of writing plain SQL again."
  spec.homepage = "https://github.com/danielfone/ensql"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "connection_pool", ">= 0.9.3", "<3"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 0.21.2"
  spec.add_development_dependency "yard", "~> 0.9.26"
end
