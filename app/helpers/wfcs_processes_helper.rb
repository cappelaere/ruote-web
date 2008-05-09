module WfcsProcessesHelper

  def result_data_helper(item)
     link = url_for :only_path => false, :controller=>"/wfcs/processes", :action =>"results", :id => item.id
     "<a href=\"#{link}\">results</a>"
   end

  def result_data_column(item)
    result_data_helper(item)
  end
  
end