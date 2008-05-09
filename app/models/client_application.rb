require 'oauth'

class ClientApplication < ActiveRecord::Base
  belongs_to :user
  has_many :tokens,:class_name=>"OauthToken"
  validates_presence_of :name,:url,:key,:secret
  validates_uniqueness_of :key
  before_validation_on_create :generate_keys
  
  #attr_accessor :realm, :user
  
  def realm
   @@realm
  end
  
  def user
    @@user
  end
     
  def self.find_token(token_key)
    @@user = nil
   
    token=OauthToken.find_by_token(token_key, :include => :client_application)
    logger.info "Loaded #{token.token} which was authorized by (user_id=#{token.user_id}) on the #{token.authorized_at}" if token
    return token if token && token.authorized?
    
    if token == nil
      # check if it is an openid of one of our users
      @@user = User.find_by_identity_url(token_key)
      if @@user
        token=AccessToken.new(:token=>token_key)
        token.user = @@user
        return token
      else
        logger.info "invalid user token: token_key"
      end
    end
    
    nil
  end
  
  def self.verify_request(request, options = {}, &block)
    begin
      logger.info "* verify: #{request.parameters.inspect}"
      signature=OAuth::Signature.build(request,options,&block)
      logger.info "* Consumer: #{signature.send :consumer_key}"
      logger.info "* Secret:#{signature.send :consumer_secret}"
      
      logger.info "* Token: #{signature.send :token}"
      #logger.info "* Realm: #{signature.request.parameters.inspect}"
      
     
      @@realm = signature.request.realm
    
      return false unless OauthNonce.remember(signature.request.nonce,signature.request.timestamp)
      
      value=signature.verify
      logger.info "*** Signature verification returned: #{value.to_s} signature_base_string:#{signature.signature_base_string}"
      value
    rescue OAuth::Signature::UnknownSignatureMethod=>e
      logger.info "ERROR:"+e.to_s
     false
    end
  end
  
  def oauth_server
    @oauth_server||=OAuth::Server.new "http://your.site"
  end
  
  def credentials
    @oauth_client||=OAuth::Consumer.new key,secret
  end
    
  def create_request_token
    RequestToken.create :client_application=>self
  end
  
  protected
  
  def generate_keys
    @oauth_client=oauth_server.generate_consumer_credentials
    self.key=@oauth_client.key
    self.secret=@oauth_client.secret
  end
end
