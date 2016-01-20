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

ActiveRecord::Schema.define(:version => 20160114025201) do

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
    t.string  "auth_type",         :limit => 30, :default => "",    :null => false
    t.string  "name",              :limit => 60, :default => "",    :null => false
    t.string  "host",              :limit => 60
    t.integer "port"
    t.string  "account",           :limit => 60
    t.string  "account_password",  :limit => 60
    t.string  "base_dn"
    t.string  "attr_login",        :limit => 30
    t.string  "attr_firstname",    :limit => 30
    t.string  "attr_lastname",     :limit => 60
    t.string  "attr_mail",         :limit => 30
    t.boolean "onthefly_register",               :default => false, :null => false
    t.string  "domain",                          :default => "",    :null => false
    t.boolean "is_internal",                     :default => false, :null => false
  end

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
  end

  create_table "properties_system_users", :force => true do |t|
    t.integer  "system_user_id",                   :null => false
    t.integer  "property_id",                      :null => false
    t.boolean  "status",         :default => true, :null => false
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
  end

  add_index "properties_system_users", ["property_id", "system_user_id"], :name => "index_properties_system_users_on_property_id_and_system_user_id", :unique => true
  add_index "properties_system_users", ["system_user_id"], :name => "fk_PropertiesSystemUsers_SystemUserId"

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
    t.string   "change_detail",      :limit => 1024, :default => "{}"
    t.string   "target_username",                                      :null => false
    t.integer  "target_property_id",                                   :null => false
    t.string   "action",                                               :null => false
    t.string   "action_by",          :limit => 1024, :default => "{}"
    t.string   "description"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
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
  end

  add_index "system_users", ["auth_source_id"], :name => "auth_source_id"

end
