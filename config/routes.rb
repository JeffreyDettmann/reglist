# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  # Defines the root path route ("/")
  root 'opportunities#index'

  namespace :admin do
    root to: 'tournaments#index'
    resources :tournaments do
      patch :update_status, on: :member
    end
  end
end
