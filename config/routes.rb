# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  # Defines the root path route ("/")
  root 'opportunities#index'

  get 'compliance/dmca'
  get 'compliance/faq'
  get 'compliance/privacy_policy'
  get 'compliance/terms'

  resource :messages, only: %i[new create]

  namespace :admin do
    root to: 'tournaments#index'
    resources :tournaments do
      patch :update_status, on: :member
      patch :toggle_request_publication, on: :member
      patch :remove_flag, on: :member
      resources :tournament_claims, only: %i[new create]
    end
    resources :tournament_claims, only: %i[index edit update destroy] do
      patch :approve, on: :member
    end
    resources :messages do
      patch :toggle_requires_action, on: :member
    end
  end
end
