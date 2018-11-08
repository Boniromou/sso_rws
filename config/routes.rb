SsoRws::Application.routes.draw do
  devise_for :system_users, controllers: { :sessions => "system_user_sessions", :registration => "system_user_registrations" }, only: :sessions

  namespace :ldap do
    get :new
    post :login
  end

  namespace :saml do
    get :new
    post :acs
    get :metadata
    get :logout
  end

  devise_scope :system_user do
    root :to => "system_user_sessions#new", :as => :app_root
    #root to: 'dashboard#home', :as => :home_root
    get "/login" => "system_user_sessions#new", :as => :login
    post '/login' => 'system_user_sessions#create'
    get "/logout" => "system_user_sessions#destroy", :as => :logout
    post "/passwords" => "system_user_registrations#update"
    # get "/register" => "system_user_registrations#new", :as => :new_system_user_registration
    # post "/register" => "system_user_registrations#create"
    get "/passwords" => "system_user_registrations#edit", :as => :edit_system_user_passwords
  end

  get "/app_login" => "internal/system_user_sessions#login"
  get "/ssrs_login" => "internal/system_user_sessions#ssrs_login"
  root :to => 'dashboard#home', :as => :root
  get 'home' => 'dashboard#home', :as => :home_root
  get 'user_management' => 'dashboard#user_management', :as => :user_management_root
  get 'role_management' => 'dashboard#role_management', :as => :role_management_root
  get 'domain_management' => 'dashboard#domain_management', :as => :domain_management_root

  resources :domains, :only => [:index, :create] do
    member do
      post 'delete'
    end
  end

  resources :ldap_details, :except => [:destroy, :show]
  resources :saml_details, :except => [:destroy, :show] do
    member do
      post 'upload'
      get 'edit_token'
    end
    collection do
      post 'delete_token'
    end
  end

  resources :domain_licensees, :only => [:index, :create] do
    collection do
      get 'get_casinos'
      post 'remove'
    end
  end

  get '/system_users/export' => 'system_users#export'
  get '/roles/export' => 'roles#export'
  get '/system_users/create_system_user_message' => 'system_users#create_system_user_message', as: :create_system_user_message

  resources :roles, :only => [:index, :show] do
    collection do
      post 'upload'
      post 'check_version'
      post 'remove'
    end
  end

   resources :permissions, :only => [:index] do
    collection do
      post 'remove'
    end
  end

  resources :system_users, :only => [:index, :show, :new, :create] do
    member do
      get 'edit_roles'
      post 'update_roles'
    end
    collection do
      post 'upload'
    end
  end

  resources :change_logs, :only => [:index] do
    collection do
      get 'create_system_user'
      get 'index_edit_role'
      get 'create_domain_licensee'
      get 'index_domain_ldap'
      get 'index_domain'
      get 'index_adfs'
      get 'index_role'
      get 'index_permission'
      get 'index_app'
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
  resources :role_permissions_versions, :only => [:index]

  resources :apps, :except => [:destroy, :new, :show] do
    member do
      post 'delete'
    end
  end

  namespace :excels do  
    get 'create_system_user_log'
    get 'login_history'
    get 'system_user_log'
  end

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

#  match "/404" => "errors#not_found"
  match "/401" => "application#handle_unauthorize"
#  match "/500" => "errors#exception"

  # Catch routing error here
  match '*unmatched', :to => 'application#handle_route_not_found', via: :get
end
