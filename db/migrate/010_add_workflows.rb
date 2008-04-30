# Use this migration to create the tables for the ActiveRecord store
class AddWorkflows < ActiveRecord::Migration
  def self.up
    create_table :workflows, :force => true do |t|
      t.string   "title",      :limit => 64
      t.string   "content"
      t.string   "category"
      t.string   "permission"
      t.datetime "created_at",                              :null => false
      t.datetime "updated_at",                              :null => false
      t.integer  "user_id"
      t.integer  "published",  :limit => 10, :default => 0, :null => false
    end
    
    add_index :workflows, ["title"], :name => "index_workflows_on_title", :unique => true
    add_index :workflows, ["published"], :name => "index_workflows_on_published"
    
    create_table :definitions, :force => true do |t|
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
  end

  def self.down
    drop_table :workflows
    drop_table :definitions
  end
end