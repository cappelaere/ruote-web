# Use this migration to create the tables for the ActiveRecord store
class AddOpenidToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :identity_url, :string, :limit =>255
    add_column :users, :email, :string, :limit =>255
    add_column :users, :fullname, :string, :limit =>255
  end

  def self.down
    remove_column :users, :identity_url
    remove_column :users, :email
    remove_column :users, :fullname
  end
end