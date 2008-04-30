class Definition < ActiveRecord::Base
  belongs_to :workflow
  
  #after_save { |record|
  #  NotifyPubsub.definition( record )
  #}
  
  def to_label
    "v#{version}"
  end
  
  def name
    workflow_name + " definition " + to_label
  end
  
  def description
    "workflow definition document for: "+ workflow_name
  end
  
  def categories
    "definitions"
  end
  
  def acl
    "n/a"
  end
  
  def workflow_name
    wf = Workflow.find(workflow_id)
    return wf.title
  end
  
  def login
    User.find(self.user_id).name
  end
  
  #
  # Find Current Version (enabled and last updated)
  # 
  def self.find_current_version( name )
    entry = Workflow.find_by_name( name )
    d = Definition.find(:first, :conditions=>["workflow_id=? AND status='enabled'", entry.id], :order=>"updated_at ASC" )  
  end
  
end
