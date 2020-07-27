Rails.application.routes.draw do
  resources :rooms do
    get :search_occupancy_rate, on: :collection
  end
  resources :reservations, only: [:new, :create, :destroy] do
    get :search, on: :collection
  end

  root to: redirect('/rooms')
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
