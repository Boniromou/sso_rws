SsoRws::Application.routes.draw do
  devise_for :system_users, controllers: { :sessions => "system_user_sessions", :registration => "system_user_registrations" }, only: :sessions

  devise_scope :system_user do
    root :to => "system_user_sessions#new", :as => :app_root
    #root to: 'dashboard#home', :as => :home_root
    get "/login" => "system_user_sessions#new", :as => :login
    post '/login' => 'system_user_sessions#create'
    get "/logout" => "system_user_sessions#destroy", :as => :logout
    get "/register" => "system_user_registrations#new", :as => :new_system_user_registration
    post "/register" => "system_user_registrations#create"
  end

  post "/internal/system_user_sessions" => "internal/system_user_sessions#create"
  #match 'home' => 'system_user_sessions#home', :as => :home

  # functional tabs on page header
  root :to => 'dashboard#home', :as => :root
  get 'home' => 'dashboard#home', :as => :home_root
  get 'user_management' => 'dashboard#user_management', :as => :user_management_root
  get 'role_management' => 'dashboard#role_management', :as => :role_management_root
  get 'audit_logs' => 'dashboard#audit_log', :as => :audit_logs_root

  resources :roles, :only => [:index]
  resources :system_users, :only => [:index, :show] do
    member do
      post 'lock'
      post 'unlock'
      match 'edit_roles'
      match 'update_roles'
    end
  end

  resources :dashboard, :only => [:index] do
    collection do
      get 'home'
      get 'user_management'
      get 'role_management'
      get 'audit_log'
    end
  end

  resources :audit_logs, :only => [:show] do
    match 'search', :via => [:get, :post], on: :collection
  end

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

#  match "/404" => "errors#not_found"
  match "/401" => "application#handle_unauthorize"
#  match "/500" => "errors#exception"

  # Catch routing error here
#  match '*unmatched', :to => 'application#render_error'
end
