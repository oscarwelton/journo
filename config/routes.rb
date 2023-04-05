Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  post '/trips/:trip_id/activities/:id/added', to: 'activities#added', as: 'add_activity_to_trip'
  post '/trips/:trip_id/activities/:id/favourite', to: 'activities#favourite', as: 'add_activity_to_favourites'

  resources :users, only: [:show]

  resources :trips, only: [:index, :new, :create, :show] do
    resources :notes, only: [:create, :edit, :update]
    resources :activities, only: [:index, :update]
  end

  resources :activities, only: []

  require "sidekiq/web"
  mount Sidekiq::Web => '/sidekiq'
end
