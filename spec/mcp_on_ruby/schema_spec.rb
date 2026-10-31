# frozen_string_literal: true

RSpec.describe McpOnRuby::Schema do
  describe ".build" do
    it "returns an empty object schema when there are no params" do
      expect(described_class.build).to eq(type: "object", properties: {})
    end

    it "accepts type shorthand" do
      expect(described_class.build(q: :string, page: :integer)).to eq(
        type: "object",
        properties: { "q" => { type: "string" }, "page" => { type: "integer" } }
      )
    end

    it "maps Ruby-style options to JSON Schema keywords" do
      schema = described_class.build(
        limit: { type: :integer, minimum: 1, maximum: 100, default: 25, description: "Page size" },
        code: { type: :string, min_length: 3, max_length: 8, pattern: "\\A[A-Z]+\\z" }
      )

      expect(schema[:properties]).to eq(
        "limit" => { type: "integer", minimum: 1, maximum: 100, default: 25, description: "Page size" },
        "code" => { type: "string", minLength: 3, maxLength: 8, pattern: "\\A[A-Z]+\\z" }
      )
    end

    it "collects required params" do
      schema = described_class.build(status: { type: :string, enum: %w[paid pending], required: true }, q: :string)

      expect(schema[:required]).to eq(["status"])
      expect(schema[:properties]["status"]).to eq(type: "string", enum: %w[paid pending])
    end

    it "expresses union and nullable types as portable anyOf branches" do
      schema = described_class.build(id: { type: %i[string integer] }, note: { type: :string, nullable: true })

      expect(schema[:properties]).to eq(
        "id" => { anyOf: [{ type: "string" }, { type: "integer" }] },
        "note" => { anyOf: [{ type: "string" }, { type: "null" }] }
      )
    end

    it "describes nested objects with a block" do
      schema = described_class.build do
        param :order, type: :object, required: true do
          param :sku, type: :string, required: true
          param :quantity, type: :integer, minimum: 1
        end
      end

      expect(schema).to eq(
        type: "object",
        properties: {
          "order" => {
            type: "object",
            properties: { "sku" => { type: "string" }, "quantity" => { type: "integer", minimum: 1 } },
            required: ["sku"]
          }
        },
        required: ["order"]
      )
    end

    it "infers an object type when a block is given without a type" do
      schema = described_class.build { param(:address) { param :city, type: :string } }

      expect(schema[:properties]["address"]).to eq(type: "object", properties: { "city" => { type: "string" } })
    end

    it "describes arrays of scalars" do
      schema = described_class.build(tags: { type: :array, items: :string, max_items: 5 })

      expect(schema[:properties]["tags"]).to eq(type: "array", maxItems: 5, items: { type: "string" })
    end

    it "describes arrays of constrained scalars" do
      schema = described_class.build(scores: { type: :array, items: { type: :integer, minimum: 0 } })

      expect(schema[:properties]["scores"]).to eq(type: "array", items: { type: "integer", minimum: 0 })
    end

    it "describes arrays of objects with a block" do
      schema = described_class.build do
        param :lines, type: :array do
          param :sku, type: :string, required: true
        end
      end

      expect(schema[:properties]["lines"]).to eq(
        type: "array",
        items: { type: "object", properties: { "sku" => { type: "string" } }, required: ["sku"] }
      )
    end

    it "combines hash params with a block" do
      schema = described_class.build(q: :string) { param :page, type: :integer }

      expect(schema[:properties].keys).to eq(%w[q page])
    end

    it "produces a schema the official SDK accepts" do
      schema = described_class.build(q: { type: :string, required: true })

      expect { MCP::Tool::InputSchema.new(schema) }.not_to raise_error
    end
  end

  describe "errors" do
    it "rejects unknown types" do
      expect { described_class.build(q: :text) }.to raise_error(ArgumentError, /unknown type text/)
    end

    it "rejects unknown options" do
      expect { described_class.build(q: { type: :string, minlength: 2 }) }
        .to raise_error(ArgumentError, /unknown option :minlength/)
    end

    it "rejects params without a type" do
      expect { described_class.build(q: { description: "Query" }) }.to raise_error(ArgumentError, /needs a type/)
    end

    it "rejects duplicate params" do
      expect { described_class.build(q: :string) { param :q, type: :string } }
        .to raise_error(ArgumentError, /declared twice/)
    end

    it "rejects blocks on scalar types" do
      expect { described_class.build { param(:q, type: :string) { param :x, type: :string } } }
        .to raise_error(ArgumentError, /only as an object or array/)
    end

    it "rejects items: together with a block" do
      expect { described_class.build { param(:l, type: :array, items: :string) { param :x, type: :string } } }
        .to raise_error(ArgumentError, /either items: or a block/)
    end
  end
end
