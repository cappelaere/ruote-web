class OauthGrant < ActiveRecord::Base
	
	def consumer=(name)
		provider = Provider.find_by_consumer_name(name)
		raise "Invalid Consumer name" if provider == nil 
		self.provider_id = provider.id
	end
	
	def consumer
		provider = Provider.find(self.provider_id).consumer_name
	end
	
	def user
		user = User.find(self.user_id).name
	end
	
end