class AppController < ApplicationController
 
  def index
    respond_to do |format|
      format.html {   }
      format.xml {
        render :content_type => "application/atomsvc+xml", :layout=>false
      }
    end
  end

end