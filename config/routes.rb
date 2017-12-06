require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  get 'static_pages/visual_components'

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  root to: 'home#root'

  post 'trazabilidad/token', to: 'traceability#get_token'
  get 'trazabilidad', to: 'traceability#endpoints_info'

  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end

  resources :schemas, only: [:index, :new, :create], param: :name do
    collection { get 'search' }
    resources :schema_versions,
      only: [:index, :new, :create, :show], param: :version_number,
      path: 'versions'
  end

  resources :services, only: [:index], controller: 'home' do
    collection do
      get 'search'
      get 'pending_approval'
    end
  end

  namespace :monitoring do
    resources :organizations, only: [:index], param: :name do
      resources :services, only: [:index, :show], param: :name do

      end
    end
  end

  resources :monitor_params

  resources :organizations, only: [:index, :show], param: :name do
    resources :services, only: [:index, :new, :create, :show], param: :name do
      post 'oauth/token', to: 'services#client_token'
      resources :service_versions,
        only: [:index, :new, :create, :show], param: :version_number,
        path: 'versions' do
          member do
            patch 'reject'
            put 'state'
            get 'source_code'
            get 'operations/:verb*path', to: 'service_versions#show', as: 'operation', constraints: {path: /\/.*/}
            get 'operations/:verb', to: 'service_versions#show', as: 'operation_on_root_path'
            post 'operations/:verb*path', to: 'service_versions#try', as: 'try_operation', constraints: {path: /\/.*/}
            post 'operations/:verb', to: 'service_versions#try', as: 'try_operation_on_root_path'
          end
      end
    end

    resources :agreements, only: [:index, :new, :create, :show] do
      patch 'state/:next_step' => 'agreements#flow_actions_router', as: 'change_state'
      resources :agreement_revisions, only: [:show, :new, :create], param: :revision_number,
        path: 'revisions'
    end
  end

  resources :users, only: [:index] do
    resources :notifications, only:[:index, :show]
  end

  if Rails.env.development?
    mount Sidekiq::Web => '/sidekiq'
  end
end
