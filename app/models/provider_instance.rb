# 
# Associate your User model (if any) to this class 
# by adding a polymorphic "has_many" relationship:
# 
#   has_many :provider_instances, :as => :user, :dependent => :destroy
# 

module OAuth
  
  module RFC3986Encoder
    # see http://groups.google.com/group/oauth/browse_thread/thread/a8398d0521f4ae3d
    def rfc3986_escape(value)
      CGI.escape(value.to_s).gsub("%7E", "~").gsub("+", "%20")
    end
  end
end

class ProviderInstance < ActiveRecord::Base
  include OAuth::RFC3986Encoder
  belongs_to :provider
  belongs_to :user, :polymorphic => true
  
  def request_token_response
    "oauth_token=#{rfc3986_escape(request_token)}&oauth_token_secret=#{rfc3986_escape(request_secret)}"
  end

  def access_token_response
    "oauth_token=#{rfc3986_escape(access_token)}&oauth_token_secret=#{rfc3986_escape(access_secret)}"
  end
end
