# Use this migration to create the tables for the ActiveRecord store
class AddProcesses < ActiveRecord::Migration
  def self.up
    create_table "wf_processes", :force => true do |t|
      t.column "definition_id", :integer
      t.column "title", :string, :limit => 64
      t.column "content", :string
      t.column "category", :string
      t.column "context_data", :text
      t.column "result_data", :text
      t.column "command", :text
      t.column "created_at", :datetime, :null => false
      t.column "updated_at", :datetime, :null => false
      t.column "status", :string, :limit => 32
      t.column "wfid", :string, :limit => 32
      t.column "user_id", :integer
      t.column "scheduled_at", :datetime
    end

    add_index "wf_processes", ["wfid"], :name => "wfid_index"
    add_index "wf_processes", ["created_at"], :name => "created_at"
    add_index "wf_processes", ["user_id"], :name => "user_id_index"
  end

  def self.down
    drop_table :wf_processes
  end
end