# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20160307082511) do

  create_table "app_system_users", :force => true do |t|
    t.integer  "system_user_id", :null => false
    t.integer  "app_id",         :null => false
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "app_system_users", ["app_id"], :name => "app_id"
  add_index "app_system_users", ["system_user_id"], :name => "system_user_id"

  create_table "apps", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "audit_logs", :force => true do |t|
    t.string   "audit_target",  :limit => 45, :null => false
    t.string   "action_type",   :limit => 45, :null => false
    t.string   "action",        :limit => 45, :null => false
    t.string   "action_status", :limit => 45, :null => false
    t.string   "action_error"
    t.string   "session_id"
    t.string   "ip",            :limit => 45
    t.string   "action_by",     :limit => 45, :null => false
    t.datetime "action_at",                   :null => false
    t.string   "description"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  create_table "auth_sources", :force => true do |t|
    t.string  "auth_type",        :limit => 30, :default => "",    :null => false
    t.string  "name",             :limit => 60, :default => "",    :null => false
    t.string  "host",             :limit => 60
    t.integer "port"
    t.string  "account",          :limit => 60
    t.string  "account_password", :limit => 60
    t.string  "base_dn"
    t.boolean "is_internal",                    :default => false, :null => false
    t.string  "encryption"
    t.string  "method"
    t.string  "search_scope"
  end

  create_table "casinos", :force => true do |t|
    t.integer  "licensee_id",               :null => false
    t.string   "name",        :limit => 45, :null => false
    t.string   "description"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "casinos", ["licensee_id"], :name => "fk_Casinos_LicenseeId"
  add_index "casinos", ["name"], :name => "index_casinos_on_name", :unique => true

  create_table "casinos_system_users", :force => true do |t|
    t.integer  "system_user_id",                   :null => false
    t.integer  "casino_id",                        :null => false
    t.boolean  "status",         :default => true, :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "casinos_system_users", ["casino_id", "system_user_id"], :name => "index_casinos_system_users_on_casino_id_and_system_user_id", :unique => true
  add_index "casinos_system_users", ["system_user_id"], :name => "fk_CasinosSystemUsers_SystemUserId"

  create_table "domains", :force => true do |t|
    t.string   "name",       :limit => 45, :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  add_index "domains", ["name"], :name => "index_domains_on_name", :unique => true

  create_table "domains_casinos", :force => true do |t|
    t.integer  "domain_id",  :null => false
    t.integer  "casino_id",  :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "domains_casinos", ["casino_id"], :name => "fk_DomainsCasinos_CasinoId"
  add_index "domains_casinos", ["domain_id", "casino_id"], :name => "index_domains_casinos_on_domain_id_and_casino_id", :unique => true

  create_table "licensees", :force => true do |t|
    t.string   "name",        :limit => 45, :null => false
    t.string   "description"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "licensees", ["name"], :name => "index_licensees_on_name", :unique => true

  create_table "permissions", :force => true do |t|
    t.string   "name"
    t.string   "action"
    t.string   "target"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "app_id"
  end

  add_index "permissions", ["app_id"], :name => "fk_Permissions_AppId"

  create_table "properties", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "name"
    t.string   "description"
    t.integer  "casino_id"
  end

  add_index "properties", ["casino_id"], :name => "fk_Properties_CasinoId"

  create_table "role_assignments", :force => true do |t|
    t.string   "user_type",  :limit => 60, :null => false
    t.integer  "user_id",                  :null => false
    t.integer  "role_id",                  :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "role_permissions", :force => true do |t|
    t.integer  "role_id",       :null => false
    t.integer  "permission_id", :null => false
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "value"
  end

  add_index "role_permissions", ["permission_id"], :name => "permission_id"
  add_index "role_permissions", ["role_id"], :name => "role_id"

  create_table "role_types", :force => true do |t|
    t.string   "name",        :null => false
    t.string   "description"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "role_types", ["name"], :name => "index_role_types_on_name", :unique => true

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
    t.integer  "app_id"
    t.integer  "role_type_id"
  end

  add_index "roles", ["app_id"], :name => "app_id"
  add_index "roles", ["role_type_id"], :name => "fk_Roles_RoleTypeId"

  create_table "system_user_change_logs", :force => true do |t|
    t.string   "change_detail",    :limit => 1024, :default => "{}"
    t.string   "target_username",                                    :null => false
    t.string   "action",                                             :null => false
    t.string   "action_by",        :limit => 1024, :default => "{}"
    t.string   "description"
    t.datetime "created_at",                                         :null => false
    t.datetime "updated_at",                                         :null => false
    t.integer  "target_casino_id",                                   :null => false
  end

  create_table "system_users", :force => true do |t|
    t.integer  "sign_in_count",      :default => 0,     :null => false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "username"
    t.boolean  "status",             :default => false, :null => false
    t.boolean  "admin",              :default => false, :null => false
    t.integer  "auth_source_id"
    t.integer  "domain_id"
  end

  add_index "system_users", ["auth_source_id"], :name => "auth_source_id"
  add_index "system_users", ["domain_id"], :name => "fk_SystemUsers_DomainId"
  add_index "system_users", ["username", "domain_id"], :name => "index_system_users_on_username_and_domain_id", :unique => true

end
