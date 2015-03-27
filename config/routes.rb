Rails.application.routes.draw do
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signin' => 'sessions#new', as: :signin
  delete '/signout' => 'sessions#destroy', as: :signout
  get '/signout' => 'sessions#destroy'
  get '/auth/failure' => 'sessions#failure', as: :failure
  get '/idle' => 'sessions#idle', as: :idle
end