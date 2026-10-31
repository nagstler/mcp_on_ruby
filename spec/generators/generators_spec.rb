# frozen_string_literal: true

require "rails/generators"
require "generators/mcp_on_ruby/install/install_generator"
require "generators/mcp_on_ruby/expose/expose_generator"

RSpec.describe "Generators" do
  around do |example|
    Dir.mktmpdir do |dir|
      @root = dir
      FileUtils.mkdir_p(File.join(dir, "config"))
      File.write(File.join(dir, "config/routes.rb"), "Rails.application.routes.draw do\nend\n")
      example.run
    end
  end

  attr_reader :root

  def run_generator(generator, args)
    capture = StringIO.new
    original = $stdout
    $stdout = capture
    generator.start(args, destination_root: root)
    capture.string
  ensure
    $stdout = original
  end

  def read(path)
    File.read(File.join(root, path))
  end

  def write_controller(path, source)
    FileUtils.mkdir_p(File.dirname(File.join(root, path)))
    File.write(File.join(root, path), source)
  end

  describe McpOnRuby::Generators::InstallGenerator do
    it "creates the initializer and mounts the engine" do
      output = run_generator(described_class, [])

      expect(read("config/initializers/mcp_on_ruby.rb")).to include("McpOnRuby.configure do |config|")
      expect(read("config/routes.rb")).to include('mount McpOnRuby::Engine, at: "/mcp"')
      expect(output).to include("bin/rails mcp:doctor")
    end

    it "mounts at a custom path" do
      run_generator(described_class, ["--path", "/agents"])

      expect(read("config/routes.rb")).to include('mount McpOnRuby::Engine, at: "/agents"')
    end
  end

  describe McpOnRuby::Generators::ExposeGenerator do
    before do
      write_controller("app/controllers/orders_controller.rb", <<~RUBY)
        class OrdersController < ApplicationController
          def index; end
        end
      RUBY
    end

    it "adds declarations with REST descriptions and write flags" do
      run_generator(described_class, %w[orders index show destroy])

      expect(read("app/controllers/orders_controller.rb")).to eq(<<~RUBY)
        class OrdersController < ApplicationController
          mcp_tool :index, description: "List orders"
          mcp_tool :show, description: "Show one order by id"
          mcp_tool :destroy, description: "Delete an order", write: true
          def index; end
        end
      RUBY
    end

    it "skips actions that are already declared" do
      run_generator(described_class, %w[orders index])
      run_generator(described_class, %w[orders index archive])

      source = read("app/controllers/orders_controller.rb")
      expect(source.scan("mcp_tool :index").size).to eq(1)
      expect(source).to include('mcp_tool :archive, description: "TODO: describe what archive does for the agent"')
    end

    it "handles namespaced controllers" do
      write_controller("app/controllers/admin/reports_controller.rb", <<~RUBY)
        module Admin
          class ReportsController < ApplicationController
          end
        end
      RUBY

      run_generator(described_class, %w[admin/reports index])

      expect(read("app/controllers/admin/reports_controller.rb")).to eq(<<~RUBY)
        module Admin
          class ReportsController < ApplicationController
            mcp_tool :index, description: "List reports"
          end
        end
      RUBY
    end

    it "fails for missing controllers" do
      expect { described_class.start(%w[invoices index], destination_root: root, debug: true) }
        .to raise_error(Thor::Error, /invoices_controller.rb does not exist/)
    end
  end
end
