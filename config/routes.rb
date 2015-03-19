SsoRws::Application.routes.draw do
  devise_for :system_users, controllers: {:sessions => "system_user_sessions"}, :skip => 'registration'

  devise_scope :system_user do
    root :to => "system_user_sessions#new"
    get "/login" => "system_user_sessions#new", :as => :login
    post '/login' => 'system_user_sessions#create', :as => :system_user_session
    get "/logout" => "system_user_sessions#destroy", :as => :logout
    get "/register" => "system_user_registrations#new", :as => :new_system_user_registration
    post "/register" => "system_user_registrations#create"
  end

  #match 'home' => 'system_user_sessions#home', :as => :home

  resources :roles, :only => [:index]
  resources :system_users
  resources :dashboard, :only => [:index] do
    collection do
      get 'home'
      get 'user_management'
      get 'role_management'
      get 'audit_log'
    end
  end
  resources :maintenances, :except => [:create, :destroy]
  resources :audit_logs, :only => [:show]
  #resources :propagations, :only => [:show]
   
  # functional tabs on page header
  #get 'dashboard' =>  'dashboard#index', :as => :dashboard
  #get 'administration' => 'application#administration_layout', :as => :administration
  #get 'property_control' =>  'application#property_control_layout', :as => :property_control
  #get 'audit_logs' => 'audit_logs#index', :as => :audit_logs
  get 'home' => 'dashboard#home', :as => :home_root
  get 'user_management' => 'system_users#index', :as => :user_management_root
  get 'role_management' => 'roles#index', :as => :role_management_root
  get 'audit_logs' => 'audit_logs#search', :as => :audit_logs_root

  # system users
  post 'system_users/:id/lock' => 'system_users#lock'
  post 'system_users/:id/unlock' => 'system_users#unlock'
  match 'system_users/:id/edit_roles' => 'system_users#edit_roles'
  match 'system_users/:id/update_roles' => 'system_users#update_roles'

  # audit_log
  match 'search_audit_logs' => 'audit_logs#search', :via => [:get, :post], :as => :search_audit_logs
  #get 'action_list/:target' => 'audit_logs#action_list'


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

#  match "/404" => "errors#not_found"
  match "/401" => "application#handle_unauthorize"
#  match "/500" => "errors#exception"

  # Catch routing error here
#  match '*unmatched', :to => 'application#render_error'
end
