# frozen_string_literal: true

require "logger"
require "rails"
require "action_controller/railtie"
require "mcp_on_ruby"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
    config.secret_key_base = "dummy-secret-key-base-for-tests-only"
    config.logger = Logger.new(nil)
    config.hosts << "www.example.com"
  end
end
