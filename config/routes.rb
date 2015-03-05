ApRws::Application.routes.draw do
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

  resources :roles
  resources :system_users
  resources :dashboard, :only => [:index]
  resources :maintenances, :except => [:create, :destroy]
  resources :audit_logs, :only => [:show]
  #resources :propagations, :only => [:show]
   
  # functional tabs on page header
  #get 'dashboard' =>  'dashboard#index', :as => :dashboard
  #get 'administration' => 'application#administration_layout', :as => :administration
  #get 'property_control' =>  'application#property_control_layout', :as => :property_control
  #get 'audit_logs' => 'audit_logs#index', :as => :audit_logs
  get 'administration' => 'system_users#index', :as => :administration_root
  get 'property_control' =>  'application#property_control_layout', :as => :property_control_root
  get 'audit_logs' => 'audit_logs#search', :as => :audit_logs_root

  # system users
  post 'system_users/:id/lock' => 'system_users#lock'
  post 'system_users/:id/unlock' => 'system_users#unlock'
  match 'system_users/:id/edit_roles' => 'system_users#edit_roles'
  match 'system_users/:id/update_roles' => 'system_users#update_roles'

  # maintenance
  get 'search_maintenance' => 'maintenances#list_scheduled', :as => :search_maintenance_root
  match 'search_maintenance/search' => 'maintenances#search', :via => [:get, :post], :as => :search_maintenance
  get 'search_maintenance/list_scheduled_maintenance' => 'maintenances#list_scheduled', :as => :scheduled_maintenance
  get 'search_maintenance/list_on_going_maintenance' => 'maintenances#list_on_going', :as => :on_going_maintenance
  post 'create_maintenance' => 'maintenances#create'
  get 'maintenances/:id/reschedule' => 'maintenances#reschedule', :as => :reschedule_maintenance
  put 'maintenances/:id/reschedule_update' => 'maintenances#reschedule_update'
  get 'maintenances/:id/extend' => 'maintenances#extend', :as => :extend_maintenance
  put 'maintenances/:id/extend_update' => 'maintenances#extend_update'
  post 'maintenances/:id/complete' => 'maintenances#complete', :as => :complete_maintenance
  match 'maintenances/:id/cancel' => 'maintenances#cancel', :as => :cancel_maintenance

  # audit_log
  match 'search_audit_logs' => 'audit_logs#search', :via => [:get, :post], :as => :search_audit_logs
  get 'action_list/:target' => 'audit_logs#action_list'

  # propagation
  post 'propagations/:id/resume' => 'propagations#resume', :as => :resume_propagation

  root :to => 'system_user_sessions#new'


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

#  match "/404" => "errors#not_found"
  match "/401" => "application#handle_unauthorize"
#  match "/500" => "errors#exception"

  # Catch routing error here
#  match '*unmatched', :to => 'application#render_error'
end
