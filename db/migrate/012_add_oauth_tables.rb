class AddOauthTables < ActiveRecord::Migration
  def self.up
    create_table :providers do |t|
      t.column :consumer_name, :string
      t.column :consumer_description, :string
      t.column :callback_url, :string
      t.column :consumer_key, :string
      t.column :consumer_secret, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :user_id, :int
    end

    create_table :oauth_grants do |g|
      g.column :user_id, :int
      g.column :provider_id, :int
      g.column :realm, :string
      g.column :created_at, :datetime
      g.column :updated_at, :datetime		
    end

    create_table :provider_instances do |t|
      t.column :provider_id, :integer
      t.column :user_id, :integer
      t.column :request_token, :string
      t.column :request_secret, :string
      t.column :access_token, :string
      t.column :access_secret, :string
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :callback_url, :string
      t.column :realm, :string
      t.column :expiry, :string
    end
  end

  def self.down
    drop_table :providers
    drop_table :oauth_grants
    drop_table :provider_instances
  end
end