class WfProcess < ActiveRecord::Base
  #has_many :traces
  
  #after_save { |record|
  #	NotifyPubsub.process( record )
  #}
  
  def login
    User.find(self.user_id).name
  end
	
end
