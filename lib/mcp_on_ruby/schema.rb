# frozen_string_literal: true

module McpOnRuby
  # Builds the JSON Schema for a tool's input from a compact Ruby DSL.
  #
  #   Schema.build(q: :string, status: { type: :string, enum: %w[paid pending], required: true })
  #
  #   Schema.build do
  #     param :order, type: :object, required: true do
  #       param :sku, type: :string, required: true
  #       param :quantity, type: :integer, minimum: 1
  #     end
  #   end
  class Schema
    TYPES = %w[string integer number boolean array object null].freeze

    # Ruby-style option names and the JSON Schema keywords they map to.
    KEYWORDS = {
      description: :description,
      title: :title,
      enum: :enum,
      const: :const,
      default: :default,
      examples: :examples,
      format: :format,
      pattern: :pattern,
      minimum: :minimum,
      maximum: :maximum,
      exclusive_minimum: :exclusiveMinimum,
      exclusive_maximum: :exclusiveMaximum,
      multiple_of: :multipleOf,
      min_length: :minLength,
      max_length: :maxLength,
      min_items: :minItems,
      max_items: :maxItems,
      unique_items: :uniqueItems
    }.freeze

    def self.build(params = {}, &)
      new.tap do |schema|
        schema.params(params)
        schema.instance_eval(&) if block_given?
      end.to_h
    end

    def initialize
      @properties = {}
      @required = []
    end

    # Declares several parameters from a hash of `name => type` or `name => options`.
    def params(definitions)
      definitions.each do |name, definition|
        case definition
        when Hash then param(name, **definition)
        else param(name, type: definition)
        end
      end
      self
    end

    # Declares a single parameter. A block describes the properties of an object,
    # or of the objects inside an array.
    def param(name, type: nil, required: false, nullable: false, items: nil, **options, &)
      name = name.to_s
      raise ArgumentError, "parameter #{name.inspect} is declared twice" if @properties.key?(name)

      type ||= "object" if block_given?
      raise ArgumentError, "parameter #{name.inspect} needs a type" unless type

      @properties[name] = property(name, type, nullable:, items:, options:, &)
      @required << name if required
      self
    end

    def to_h
      schema = { type: "object", properties: @properties }
      schema[:required] = @required unless @required.empty?
      schema
    end

    private

    def property(name, type, nullable:, items:, options:, &)
      types = json_types(name, type, nullable)
      schema = type_schema(types)
      schema.merge!(keywords(name, options))
      schema.merge!(nested(name, types, items, &))
      schema
    end

    def json_types(name, type, nullable)
      types = Array(type).map(&:to_s)
      unknown = types - TYPES
      raise ArgumentError, "parameter #{name.inspect} has unknown type #{unknown.join(", ")}" if unknown.any?

      types << "null" if nullable && !types.include?("null")
      types
    end

    # Several types become `anyOf` branches rather than a `type` array, which some model
    # providers' schema dialects reject.
    def type_schema(types)
      types.one? ? { type: types.first } : { anyOf: types.map { |type| { type: } } }
    end

    def keywords(name, options)
      options.each_with_object({}) do |(option, value), schema|
        keyword = KEYWORDS.fetch(option) do
          raise ArgumentError, "parameter #{name.inspect} has unknown option #{option.inspect}"
        end
        schema[keyword] = value
      end
    end

    def nested(name, types, items, &)
      if types.include?("array")
        array_items(name, items, &)
      elsif block_given?
        unless types.include?("object")
          raise ArgumentError, "parameter #{name.inspect} takes a block only as an object or array"
        end

        nested_object(&)
      else
        {}
      end
    end

    def array_items(name, items, &)
      raise ArgumentError, "parameter #{name.inspect} takes either items: or a block, not both" if items && block_given?

      return { items: { type: "object" }.merge(nested_object(&)) } if block_given?
      return {} unless items

      { items: items.is_a?(Hash) ? item_schema(name, **items) : type_schema(json_types(name, items, false)) }
    end

    def item_schema(name, type:, nullable: false, **options)
      type_schema(json_types(name, type, nullable)).merge(keywords(name, options))
    end

    def nested_object(&)
      object = self.class.new
      object.instance_eval(&)
      object.to_h.except(:type)
    end
  end
end
