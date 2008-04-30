module WfcsWorkflowsHelper
  def post_link(item)
    url_for :only_path => false, :controller=>"/wfcs/workflows", :action =>"show", :id => item.id.to_s 
  end
  
  def item_id( item )
    url_for :only_path => false, :controller=>"/wfcs/workflows", :id => item.id.to_s   
  end
  
  def atom_link( item )
    url_for :only_path => false, :controller=>"/wfcs/workflows", :action =>"show", :id => item.id.to_s 
  end
  
  def xforms_link( item )
    defrec = Definition.find(:first, :conditions=>["workflow_id=? AND status='enabled'", item.id], :order=>"updated_at ASC" )
    url =  url_for(:only_path => false, :controller=>'/wfcs/definitions', :action =>"xform", :id => defrec.id)
    "<a href='#{url}'>click here</a>"
  end
  
  def template_link( item )
     defrec = Definition.find(:first, :conditions=>["workflow_id=? AND status='enabled'", item.id], :order=>"updated_at ASC" )
     url =  url_for(:only_path => false, :controller=>'/wfcs/definitions', :action =>"template", :id => defrec.id)
     "<a href='#{url}'>click here</a>"
  end
  
  def definition(item)
      defrec = Definition.find(:first, :conditions=>["workflow_id=? AND status='enabled'", item.id], :order=>"updated_at ASC" )

       if defrec.link  && defrec.link != '[Null]'
         file = "/images/workflows/#{defrec.link}"
         "<a href='#{file}'><img src='#{file}' width='100'/></a>"
       end
   end
end