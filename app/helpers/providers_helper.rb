module ProvidersHelper
  
  def username_column(item)
    User.find(item.user_id).name
  end
end
