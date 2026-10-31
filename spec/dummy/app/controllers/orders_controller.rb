# frozen_string_literal: true

# A token-authenticated JSON API, the way many Rails apps expose data today.
class OrdersController < ActionController::API
  before_action :authenticate!
  before_action :set_order, only: %i[show update destroy]

  mcp_tool :index, description: "Search the current user's orders",
                   params: { status: { type: :string, enum: Order::STATUSES } }
  mcp_tool :show, description: "Fetch one order by id"
  mcp_tool :create, description: "Place an order", write: true do
    param :order, required: true do
      param :sku, type: :string, required: true
      param :quantity, type: :integer, minimum: 1
    end
  end
  mcp_tool :update, description: "Change an order's status", write: true,
                    params: { status: { type: :string, required: true } }
  mcp_tool :destroy, description: "Cancel an order", write: true

  def index
    orders = Order.all.select { |order| order.user_id == @current_user.id }
    orders = orders.select { |order| order.status == params[:status] } if params[:status].present?
    render json: orders
  end

  def show
    render json: @order
  end

  def create
    attributes = params.expect(order: %i[sku quantity]) if params.respond_to?(:expect)
    attributes ||= params.require(:order).permit(:sku, :quantity)
    order = Order.create(user_id: @current_user.id, sku: attributes[:sku], quantity: attributes[:quantity].to_i)

    if order.errors.empty?
      render json: order, status: :created
    else
      render json: { errors: order.errors }, status: 422
    end
  end

  def update
    @order.status = params.require(:status)
    if @order.valid?
      render json: @order
    else
      render json: { errors: @order.errors }, status: 422
    end
  end

  def destroy
    Order.all.delete(@order)
    head :no_content
  end

  private

  def authenticate!
    token = request.authorization.to_s.delete_prefix("Bearer ")
    @current_user = User.find_by(token:)
    render json: { error: "unauthenticated" }, status: :unauthorized unless @current_user
  end

  def set_order
    @order = Order.find(params[:id])
    return render json: { error: "not found" }, status: :not_found unless @order

    render json: { error: "forbidden" }, status: :forbidden unless @order.user_id == @current_user.id
  end
end
