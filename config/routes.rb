Rails.application.routes.draw do
  root controller: :dashboard, action: :show

  resource :dashboard, controller: 'dashboard', only: [:show] do
  end

  resource :orcid, controller: 'orcid' do
    get :landing
  end
  namespace :api do
    resources :users
  end

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
