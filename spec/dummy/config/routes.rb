# frozen_string_literal: true

Rails.application.routes.draw do
  mount McpOnRuby::Engine, at: "/mcp"

  resources :orders
  resource :profile, only: :show
  resources :notes, only: :create

  get "pages/html", to: "pages#html"
  get "pages/text", to: "pages#text"
  get "pages/moved", to: "pages#moved"
  get "pages/crash", to: "pages#crash"
  get "pages/noisy", to: "pages#noisy"
  get "pages/echo", to: "pages#echo"

  namespace :admin do
    resources :reports, only: :index
  end
end
