# frozen_string_literal: true

# In-memory orders so the dummy app needs no database.
class Order
  STATUSES = %w[pending paid shipped].freeze

  attr_reader :id, :user_id, :sku, :quantity, :errors
  attr_accessor :status

  def initialize(id:, user_id:, sku:, quantity: 1, status: "pending")
    @id = id
    @user_id = user_id
    @sku = sku
    @quantity = quantity
    @status = status
    @errors = []
  end

  class << self
    def all
      @all ||= seed
    end

    def reset!
      @all = seed
    end

    def find(id)
      all.find { |order| order.id == Integer(id, exception: false) }
    end

    def create(**attributes)
      order = new(id: all.map(&:id).max.to_i + 1, **attributes)
      all << order if order.valid?
      order
    end

    private

    def seed
      [
        new(id: 1, user_id: 1, sku: "BOOK-1", status: "pending"),
        new(id: 2, user_id: 1, sku: "PEN-2", status: "paid"),
        new(id: 3, user_id: 2, sku: "LAMP-3", status: "shipped")
      ]
    end
  end

  def valid?
    @errors = []
    @errors << "sku can't be blank" if sku.to_s.strip.empty?
    @errors << "quantity must be greater than 0" unless quantity.to_i.positive?
    @errors << "status is not included in the list" unless STATUSES.include?(status)
    @errors.empty?
  end

  def as_json(*)
    { "id" => id, "user_id" => user_id, "sku" => sku, "quantity" => quantity, "status" => status }
  end
end
