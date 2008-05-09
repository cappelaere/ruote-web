module WfcsDefinitionsHelper
  def definition_entry_title(item)
    Workflow.find(item.workflow_id).title + " definition v#{item.version}"
  end

  def xpdl(item)
    link = url_for :only_path => false, :controller=>"/wfcs_definitions", :action =>"xpdl", :id => item.id
    "<a href='#{link}'>here</a>"
  end

  def xform(item)
    link = url_for :only_path => false, :controller=>"/wfcs_definitions", :action =>"xform", :id => item.id
    "<a href='#{link}'>here</a>" if item.xform && item.xform != ''
  end
  
  def template(item)
    link = url_for :only_path => false, :controller=>"/wfcs_definitions", :action =>"template", :id => item.id
    "<a href='#{link}'>here</a>" if item.xform && item.xform != ''
  end
  
  def flow(item)
    link = url_for :only_path => false, :controller=>"/wfcs_definitions", :action =>"flow", :id => item.id
    file = "/images/workflows/#{item.link}"
    if item.link
      "<a href='#{link}'><img src='#{file}' width='100'/></a>" 
    else
      ""
    end
  end

  def openwfe(item)
    link = url_for :only_path => false, :controller=>"/wfcs_definitions", :action =>"openwfe", :id => item.id
    "<a href='#{link}'>here</a>"
  end

  def openwfe_column(item)
     openwfe(item)
   end

   def xpdl_column(item)
     xpdl(item)
   end

   def flow_column(item)
     if item.link && item.link != '' && item.link != '[Null]'
        link = url_for :only_path => false, :controller=>"/wfcs/definitions", :action =>"flow", :id => item.id
        "<a href='#{link}'>diagram</a>"
     else
        "n/a"
     end
   end
   
   def template_column(item)
     xform = item.xform
     template(item) if xform && xform != ''
   end
   
end