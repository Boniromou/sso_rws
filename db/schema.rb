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

ActiveRecord::Schema.define(:version => 20150121045233) do

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
  end

  create_table "maintenance_types", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "maintenances", :force => true do |t|
    t.integer  "property_id"
    t.integer  "maintenance_type_id"
    t.datetime "start_time",                         :null => false
    t.datetime "end_time",                           :null => false
    t.integer  "duration",                           :null => false
    t.boolean  "allow_test_account",                 :null => false
    t.string   "status",                             :null => false
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "expired_at"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "lock_version",        :default => 0
  end

  add_index "maintenances", ["maintenance_type_id"], :name => "fk_maintenance_type_id"
  add_index "maintenances", ["property_id"], :name => "fk_property_id"

  create_table "propagations", :force => true do |t|
    t.integer  "maintenance_id"
    t.string   "status",                        :null => false
    t.integer  "retry",          :default => 0, :null => false
    t.string   "action",                        :null => false
    t.datetime "propagating_at"
    t.datetime "propagated_at"
    t.datetime "broken_at"
    t.datetime "cancelled_at"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.integer  "lock_version",   :default => 0
  end

  add_index "propagations", ["maintenance_id"], :name => "fk_maintenance_id"

  create_table "properties", :force => true do |t|
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "name"
    t.string   "description"
  end

  create_table "role_assignments", :force => true do |t|
    t.string   "user_type",  :limit => 60, :null => false
    t.integer  "user_id",                  :null => false
    t.integer  "role_id",                  :null => false
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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

  create_table "tests", :force => true do |t|
    t.string   "name",       :limit => 20
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

end
