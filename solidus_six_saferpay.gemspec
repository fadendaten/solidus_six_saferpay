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

  spec.add_dependency "rails", "~> 5.1"
  spec.add_dependency "solidus", "~> 2.7"
  spec.add_dependency "rails-i18n", "~> 5.1"
  spec.add_dependency "six_saferpay", "~> 2.2"

  spec.add_development_dependency "solidus_dev_support", "~> 1.0"
  spec.add_development_dependency "sqlite3", "~> 1.4"
  spec.add_development_dependency "factory_bot_rails", "~> 5.0"
  spec.add_development_dependency "shoulda-matchers", "~> 4.1"
  spec.add_development_dependency "pry", "~> 0.12"
  spec.add_development_dependency "pry-rails", "~> 0.3"
  spec.add_development_dependency "simplecov", "~> 0.17"
end
