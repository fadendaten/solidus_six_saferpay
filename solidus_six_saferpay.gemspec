$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "solidus_six_saferpay/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "solidus_six_saferpay"
  spec.version     = SolidusSixSaferpay::VERSION
  spec.authors     = ["Simon Kiener"]
  spec.email       = ["jugglinghobo@gmail.com"]
  spec.homepage    = "http://fadendaten.ch"
  spec.summary     = "Saferpay Payment Page and Transaction payment methods for Solidus"
  spec.description = "Adds Saferpay Payment Page and Transaction payment methods to your Solidus application"
  spec.license     = "MIT"

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", ">= 5.1.0"
  spec.add_dependency "solidus", ">= 2.7.1"
  spec.add_dependency "solidus_support"
  spec.add_dependency "rails-i18n", ">= 5.1.0"
  spec.add_dependency "six_saferpay"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "rspec-rails"
  spec.add_development_dependency "factory_bot_rails"
  spec.add_development_dependency "shoulda-matchers"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-rails"
  spec.add_development_dependency "simplecov"

  # required by solidus_support
  spec.add_development_dependency 'database_cleaner'
  spec.add_development_dependency 'ffaker'
end
