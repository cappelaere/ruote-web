require 'builder'
require 'date'
require 'lib/wfcs/utils'

class WfcsWorkflowsController < ApplicationController

  include Wfcs
  
  active_scaffold :workflows
  layout 'workflows'
  
  def index
    @items = Workflow.find(:all, :conditions=>["published=1"])
    respond_to do |format|
      format.html { redirect_to :action=>'list', :format=>'html' }
      format.xml  { redirect_to :action=>'list', :format=>'xml' }
      format.atom { generate_atom_feed }
      format.metadata { 
        obj = Workflow.find(:first)
        render :xml => metadata(obj), :content_type => Mime::XML, :status => 200    
      }
    end
  end
  
  private
  
  def generate_atom_feed
    @feed_title = "Worflow Feed"
    @today = Date.today
    render :action=>'atom_feed', :layout=>false
  end
end