# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 14) do

  create_table "client_applications", :force => true do |t|
    t.string   "name"
    t.string   "url"
    t.string   "support_url"
    t.string   "callback_url"
    t.string   "key",          :limit => 50
    t.string   "secret",       :limit => 50
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "client_applications", ["key"], :name => "index_client_applications_on_key", :unique => true

  create_table "definitions", :force => true do |t|
    t.integer  "workflow_id"
    t.integer  "user_id",                   :default => 1
    t.string   "version",     :limit => 12
    t.text     "xpdl"
    t.text     "openwfe"
    t.datetime "created_at",                                       :null => false
    t.datetime "updated_at",                                       :null => false
    t.string   "status",      :limit => 32, :default => "enabled"
    t.string   "link"
    t.string   "xform",                     :default => "",        :null => false
  end

  add_index "definitions", ["workflow_id"], :name => "workflow_id_idx"

  create_table "fields", :force => true do |t|
    t.string  "fkey",        :default => "", :null => false
    t.string  "vclass",      :default => "", :null => false
    t.string  "svalue"
    t.text    "yvalue"
    t.integer "workitem_id",                 :null => false
  end

  add_index "fields", ["workitem_id", "fkey"], :name => "index_fields_on_workitem_id_and_fkey", :unique => true
  add_index "fields", ["fkey"], :name => "index_fields_on_fkey"
  add_index "fields", ["vclass"], :name => "index_fields_on_vclass"
  add_index "fields", ["svalue"], :name => "index_fields_on_svalue"

  create_table "groups", :force => true do |t|
    t.string "name",     :default => "", :null => false
    t.string "username", :default => "", :null => false
  end

  create_table "launch_permissions", :force => true do |t|
    t.string "groupname", :default => "", :null => false
    t.string "url",       :default => "", :null => false
  end

  create_table "oauth_grants", :force => true do |t|
    t.integer  "user_id"
    t.integer  "client_application_id"
    t.string   "realm"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "oauth_nonces", :force => true do |t|
    t.string   "nonce"
    t.integer  "timestamp"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_nonces", ["nonce", "timestamp"], :name => "index_oauth_nonces_on_nonce_and_timestamp", :unique => true

  create_table "oauth_tokens", :force => true do |t|
    t.integer  "user_id"
    t.string   "type",                  :limit => 20
    t.integer  "client_application_id"
    t.string   "token",                 :limit => 50
    t.string   "secret",                :limit => 50
    t.datetime "authorized_at"
    t.datetime "invalidated_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "oauth_tokens", ["token"], :name => "index_oauth_tokens_on_token", :unique => true

  create_table "open_id_associations", :force => true do |t|
    t.binary  "server_url"
    t.string  "handle"
    t.binary  "secret"
    t.integer "issued"
    t.integer "lifetime"
    t.string  "assoc_type"
  end

  create_table "open_id_nonces", :force => true do |t|
    t.string  "server_url", :default => "", :null => false
    t.integer "timestamp",                  :null => false
    t.string  "salt",       :default => "", :null => false
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id", :default => "", :null => false
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["updated_at"], :name => "index_sessions_on_updated_at"

  create_table "store_permissions", :force => true do |t|
    t.string "storename",  :default => "", :null => false
    t.string "groupname",  :default => "", :null => false
    t.string "permission", :default => "", :null => false
  end

  create_table "users", :force => true do |t|
    t.string  "name",            :default => "",    :null => false
    t.string  "hashed_password", :default => "",    :null => false
    t.string  "salt",            :default => "",    :null => false
    t.boolean "admin",           :default => false, :null => false
    t.string  "identity_url"
    t.string  "email"
    t.string  "fullname"
  end

  create_table "wf_processes", :force => true do |t|
    t.integer  "definition_id"
    t.string   "title",         :limit => 64
    t.string   "content"
    t.string   "category"
    t.text     "context_data"
    t.text     "result_data"
    t.text     "command"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
    t.string   "status",        :limit => 32
    t.string   "wfid",          :limit => 32
    t.integer  "user_id"
    t.datetime "scheduled_at"
  end

  add_index "wf_processes", ["wfid"], :name => "wfid_index"
  add_index "wf_processes", ["created_at"], :name => "created_at"
  add_index "wf_processes", ["user_id"], :name => "user_id_index"

  create_table "wi_stores", :force => true do |t|
    t.string "name"
    t.string "regex"
  end

  create_table "workflows", :force => true do |t|
    t.string   "title",      :limit => 64
    t.string   "content"
    t.string   "category"
    t.string   "permission"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.integer  "user_id"
    t.integer  "published",  :limit => 10, :default => 0, :null => false
  end

  add_index "workflows", ["title"], :name => "index_workflows_on_title", :unique => true
  add_index "workflows", ["published"], :name => "index_workflows_on_published"

  create_table "workitems", :force => true do |t|
    t.string   "fei"
    t.string   "wfid"
    t.string   "wf_name"
    t.string   "wf_revision"
    t.string   "participant_name"
    t.string   "store_name"
    t.datetime "dispatch_time"
    t.datetime "last_modified"
    t.text     "yattributes"
  end

  add_index "workitems", ["fei"], :name => "index_workitems_on_fei", :unique => true
  add_index "workitems", ["wfid"], :name => "index_workitems_on_wfid"
  add_index "workitems", ["wf_name"], :name => "index_workitems_on_wf_name"
  add_index "workitems", ["wf_revision"], :name => "index_workitems_on_wf_revision"
  add_index "workitems", ["participant_name"], :name => "index_workitems_on_participant_name"
  add_index "workitems", ["store_name"], :name => "index_workitems_on_store_name"

end
