# frozen_string_literal: true

require_relative 'lib/solidus_six_saferpay/version'

Gem::Specification.new do |spec|
  spec.name = 'solidus_six_saferpay'
  spec.version = SolidusSixSaferpay::VERSION
  spec.authors = ['Simon Kiener']
  spec.email = ['jugglinghobo@gmail.com']

  spec.summary = 'Saferpay Payment Page and Transaction payment methods for Solidus'
  spec.description = 'Adds Saferpay Payment Page and Transaction payment methods to your Solidus application'
  spec.homepage = 'https://github.com/fadendaten/solidus_six_saferpay'
  spec.license = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/fadendaten/solidus_six_saferpay'
  spec.metadata['changelog_uri'] = 'https://github.com/fadendaten/solidus_six_saferpay/blob/master/CHANGELOG.md'

  spec.required_ruby_version = Gem::Requirement.new('~> 2.6')

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  files = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }

  spec.files = files.grep_v(%r{^(test|spec|features)/})
  spec.test_files = files.grep(%r{^(test|spec|features)/})
  spec.bindir = "exe"
  spec.executables = files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rails-i18n', '~> 6.1'
  spec.add_dependency 'six_saferpay'#, '~> 2.8.2'
  spec.add_dependency 'solidus_core', ['>= 2.0.0', '< 4']
  spec.add_dependency 'solidus_support', '~> 0.8.1'

  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rails-controller-testing', '~> 1.0', '>= 1.0.4'
  spec.add_development_dependency 'rubocop', '~> 1.18', '>= 1.18.3'
  spec.add_development_dependency 'shoulda-matchers', '~> 5.0.0'
  spec.add_development_dependency 'solidus_dev_support', '~> 2.5'
end
