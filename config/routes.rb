Rails.application.routes.draw do
  root to: 'words#index'

  get '/index', to: 'words#index'

  post '/result', to: 'words#result'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
