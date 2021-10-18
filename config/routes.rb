Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/protected', to: "pages#protected", as: 'protected'
  post '/login', to: "login#login", as: 'login'
  post '/logout', to: "login#logout", as: 'logout'

  root to: "pages#root"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
