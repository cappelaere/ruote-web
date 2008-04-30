class WfcsAppController < ApplicationController
  layout 'densha'
  
  def index
    respond_to do |format|
      format.html {   }
      format.xml {
        render :layout=>false
      }
      format.atom {
        render :content_type => "application/atomsvc+xml", :layout=>false        
      }
    end
  end

end