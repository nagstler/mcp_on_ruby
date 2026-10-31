# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    Order.reset!
    McpOnRuby.reset_configuration!
    McpOnRuby.registry.reset!
  end
end
