class Workflow < ActiveRecord::Base

  #after_save { |record|
  #  NotifyPubsub.workflow( record )
  #}
  
  has_many :definitions
  
  def login
    User.find(self.user_id).name
  end
  
  validates_uniqueness_of :title
end
