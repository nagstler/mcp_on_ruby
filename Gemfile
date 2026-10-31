# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Run the suite against a specific Rails series, e.g. RAILS_VERSION=7.2 bundle install
rails_version = ENV.fetch("RAILS_VERSION", "8.1")
gem "rails", "~> #{rails_version}.0"

gem "rake", "~> 13.2"
gem "rspec", "~> 3.13"
gem "simplecov", "~> 0.22", require: false
gem "warden", "~> 1.2"

group :lint do
  gem "rubocop", "~> 1.80", require: false
  gem "rubocop-performance", "~> 1.25", require: false
  gem "rubocop-rake", "~> 0.7", require: false
  gem "rubocop-rspec", "~> 3.6", require: false
end
