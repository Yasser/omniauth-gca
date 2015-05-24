GcaSsoClient::Engine.routes.draw do
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signin' => 'sessions#new', as: :signin
  delete '/signout(/:catch_message)' => 'sessions#destroy', as: :signout
  get '/signout' => 'sessions#destroy'
  get '/auth/failure' => 'sessions#failure', as: :failure
  get '/idle' => 'sessions#idle', as: :idle
  
  resources :users, only: [:index, :destroy] do
    collection do
      patch 'sync/(:force)', to: 'users#sync', as: :sync
    end
  end
end