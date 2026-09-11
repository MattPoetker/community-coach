# frozen_string_literal: true

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "health/ready" => "health#ready"

  namespace :auth do
    post "register" => "registrations#create"
    post "confirm" => "registrations#confirm"
    post "login" => "sessions#create"
    delete "logout" => "sessions#destroy"
    delete "sessions" => "sessions#destroy_all"
    post "password/reset" => "passwords#create"
    put "password" => "passwords#update"
  end

  namespace :api do
    namespace :v1 do
      resource :community, only: %i[show update], controller: "communities" do
        get :branding
      end

      resources :categories, only: %i[index create update]

      resources :posts, only: %i[index show create update destroy] do
        member do
          post :pin
          post :lock
        end
        resources :comments, only: %i[index create]
      end
      resources :comments, only: %i[update destroy]

      post "reactions/toggle" => "reactions#toggle"

      resources :courses, only: %i[index show]
      resources :lessons, only: %i[show] do
        member { put :progress }
      end

      resources :events, only: %i[index] do
        member { post :rsvp }
      end

      resources :members, only: %i[index update] do
        member { post :suspend }
        collection { get :me }
      end

      resources :notifications, only: %i[index] do
        member { post :read }
        collection { post :read_all }
      end

      get "search" => "search#index"

      post "checkout" => "checkout#create"
      post "checkout/portal" => "checkout#portal"

      resources :reports, only: %i[index create] do
        member { post :resolve }
      end

      resources :invitations, only: %i[index create destroy]

      resources :join_requests, only: %i[index create] do
        member { post :review }
      end

      resources :notification_preferences, only: %i[index update]

      namespace :admin do
        resources :categories, only: %i[destroy] do
          collection { post :reorder }
        end
        resources :courses, only: %i[index create update destroy] do
          member { post :publish }
        end
        resources :lessons, only: %i[create update destroy] do
          collection do
            post :reorder
            post :upload_url
            post :uploaded
          end
        end
        resources :events, only: %i[create update destroy]
        resources :plans, only: %i[index create update destroy]
      end

      post "webhooks/stripe" => "webhooks#stripe"
    end
  end
end
