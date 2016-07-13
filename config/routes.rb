Rails.application.routes.draw do
  get 'static_pages/visual_components'
  get 'agreements/index'
  get 'agreements/show'
  get 'agreements/new'
  get 'agreements/edit'

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#root'

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

  resources :organizations, only: [:index], param: :name do
    resources :services, only: [:index, :new, :create, :show], param: :name do
      resources :service_versions,
        only: [:index, :new, :create, :show], param: :version_number,
        path: 'versions' do
          member do
            put 'state'
            get 'source_code'
          end
      end
    end
  end

  resources :users, only: [:index] do
    resources :notifications, only:[:index, :show]
  end

end
