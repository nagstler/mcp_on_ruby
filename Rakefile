# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  desc "Run RuboCop (unavailable: install the lint group)"
  task :rubocop do
    warn "RuboCop is not installed; skipping lint."
  end
end

task default: %i[spec rubocop]
