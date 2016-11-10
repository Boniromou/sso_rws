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
  root :to => 'dashboard#home', :as => :root
  get 'home' => 'dashboard#home', :as => :home_root
  get 'user_management' => 'dashboard#user_management', :as => :user_management_root
  get 'role_management' => 'dashboard#role_management', :as => :role_management_root
  get 'domain_management' => 'dashboard#domain_management', :as => :domain_management_root

  resources :domains, :only => [:index, :create]
  resources :domain_licensees, :only => [:index, :create] do
    collection do
      get 'get_casinos'
      post 'remove'
    end
  end

  get '/system_users/export' => 'system_users#export'
  get '/roles/export' => 'roles#export'
  get '/system_users/create_system_user_message' => 'system_users#create_system_user_message', as: :create_system_user_message
  resources :roles, :only => [:index, :show]
  resources :system_users, :only => [:index, :show, :new, :create] do
    member do
      get 'edit_roles'
      post 'update_roles'
    end
  end

  resources :change_logs, :only => [:index] do
    collection do
      get 'create_system_user'
      get 'index_edit_role'
      get 'create_domain_licensee'
    end
  end

  resources :dashboard, :only => [:index] do
    collection do
      get 'home'
      get 'user_management'
      get 'role_management'
    end
  end

  resources :audit_logs, :only => [:show] do
    match 'search', :via => [:get, :post], on: :collection
  end

  resources :login_histories, :only => [:index]

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

#  match "/404" => "errors#not_found"
  match "/401" => "application#handle_unauthorize"
#  match "/500" => "errors#exception"

  # Catch routing error here
  match '*unmatched', :to => 'application#handle_route_not_found', via: :get
end
