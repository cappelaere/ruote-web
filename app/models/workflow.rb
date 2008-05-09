class Workflow < ActiveRecord::Base

  #after_save { |record|
  #  NotifyPubsub.workflow( record )
  #}
  
  ##
  # permalink the title
  before_save { |record|
    record.title =    record.title.downcase.tr("\"'", '').gsub(/\W/, ' ').strip.tr_s(' ', '-').tr(' ', '-').sub(/^$/, "-")
  }
  
  has_many :definitions

   
  def login
    User.find(self.user_id).name
  end
  
  validates_uniqueness_of :title
end
