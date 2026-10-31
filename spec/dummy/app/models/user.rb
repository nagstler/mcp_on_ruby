# frozen_string_literal: true

class User
  attr_reader :id, :email, :token

  def initialize(id:, email:, token:)
    @id = id
    @email = email
    @token = token
  end

  def self.all
    @all ||= [
      new(id: 1, email: "alice@example.com", token: "alice-token"),
      new(id: 2, email: "bob@example.com", token: "bob-token")
    ]
  end

  def self.find_by(**attributes)
    all.find { |user| attributes.all? { |name, value| user.public_send(name) == value } }
  end
end
