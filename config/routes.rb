Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get  '/protected', to: "pages#protected", as: 'protected'
  post '/login',     to: "login#login",     as: 'login'
  post '/logout',    to: "login#logout",    as: 'logout'

  post '/send_email_auth', to: "login#send_email_auth", as: 'send_email_auth'
  get  '/email_auth',      to: "login#email_auth",      as: 'email_auth'

  post '/send_password_reset', to: "login#send_password_reset", as: 'send_password_reset'
  get  '/password_reset',      to: "login#password_reset",      as: 'password_reset'
  post '/password_reset',      to: "login#do_password_reset",   as: 'do_password_reset'

  root to: "pages#root"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
