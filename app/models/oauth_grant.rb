class OauthGrant < ActiveRecord::Base
	
	def client_name=(name)
		client = ClientApplication.find_by_name(name)
		raise "Invalid Client Application name" if client == nil 
		self.client_application_id = client.id
	end
	
	def client_name
	  begin
		  ClientApplication.find(self.client_application_id).name
	  rescue
    end
	end
	
	def user
		user = User.find(self.user_id).name
	end
	
end