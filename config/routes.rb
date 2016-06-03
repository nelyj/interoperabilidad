Rails.application.routes.draw do
  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: 'home#index'

  devise_scope :user do
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
    delete 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
  end

  resources :schemas, only: [:index, :new, :create, :edit, :update], param: :name do
      resources :schema_versions,
        only: [:index, :new, :create, :show], param: :version_number,
        path: 'versions'
  end
end
