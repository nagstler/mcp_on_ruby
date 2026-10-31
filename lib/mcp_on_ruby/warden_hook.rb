# frozen_string_literal: true

module McpOnRuby
  # Signs in the stdio user for Warden and Devise apps, for the duration of one dispatched request.
  #
  # The user is read from the request env, never from a header, so HTTP clients cannot set it.
  # Nothing is written to the session.
  module WardenHook
    module_function

    def install!
      return if @installed || !defined?(::Warden::Manager)

      ::Warden::Manager.on_request do |proxy|
        user = proxy.env[McpOnRuby::USER_ENV_KEY]
        proxy.set_user(user, scope: McpOnRuby.configuration.warden_scope, store: false, run_callbacks: false) if user
      end
      @installed = true
    end
  end
end
