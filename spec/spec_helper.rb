# frozen_string_literal: true

if ENV["COVERAGE"] != "false"
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
    # HTML for local runs, JSON for the coverage upload in CI.
    formatter SimpleCov::Formatter::MultiFormatter.new([SimpleCov::Formatter::HTMLFormatter,
                                                        SimpleCov::Formatter::JSONFormatter])
    enable_coverage :branch
  end
end

ENV["RAILS_ENV"] = "test"
require_relative "dummy/config/environment"

Dir[File.join(__dir__, "support/**/*.rb")].each { |file| require file }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  Kernel.srand config.seed
end
