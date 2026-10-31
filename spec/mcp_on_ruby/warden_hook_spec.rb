# frozen_string_literal: true

RSpec.describe McpOnRuby::WardenHook do
  it "installs its Warden callback only once" do
    callbacks = Warden::Manager._on_request

    expect { 2.times { described_class.install! } }.not_to(change { callbacks.size })
  end

  it "signs the stdio user in under the configured scope" do
    McpOnRuby.configure { |config| config.warden_scope = :admin }
    context = McpOnRuby::CallContext.new(transport: :stdio, user: User.find_by(id: 1))

    # ProfilesController authenticates the :user scope, which the stdio user is no longer signed into.
    response = McpOnRuby::Dispatcher.new.call(McpOnRuby.registry.find("profiles_show"), {}, context)

    expect(response.content.first[:text]).to start_with("Not authenticated (401)")
  end
end
