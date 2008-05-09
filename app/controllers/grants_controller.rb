class GrantsController < ApplicationController
	layout 'grants'

	before_filter :authorize	
	active_scaffold :oauth_grant
	
	active_scaffold :oauth_grant do |config|
	  config.label 	 = "Grants Entries"
	  config.columns = [ :client_name, :realm, :created_at, :updated_at]
	  
	  config.create.columns = [ :client_name, :realm]

	  list.sorting = {:realm => 'ASC'}
	end	
	
	# restrict to displaying the user's grants only
	def conditions_for_collection
	  ['user_id = ?', session[:user].id ]
	end			
	
	# make sure we save the user id in the grant record to filter it
	def before_create_save(record)
		record.user_id = session[:user].id
	end
	  	
end
