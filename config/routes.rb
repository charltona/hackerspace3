Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  resources :users

  namespace :admin do
    resources :assignments, :regions
  end

  get 'manage_account', to: 'users#show'
  get 'edit_personal_details', to: 'users#edit'
  get 'competition_management', to: 'admin/assignments#index'

  root 'static_pages#index'
end
