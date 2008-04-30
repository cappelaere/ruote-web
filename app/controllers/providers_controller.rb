#require 'provider'
#require 'provider_instance'

class ProvidersController < ApplicationController
  before_filter :authorize
  	
  #layout 'providers'
  active_scaffold :provider

  active_scaffold :provider do |config|
    config.label 	 = "Consumers Entries"
    config.columns = [ :consumer_name, :consumer_description, :callback_url, :consumer_key, :consumer_secret, :created_at, :updated_at, :username]

    #config.create.columns = [ :username ]

    list.sorting = {:consumer_name => 'ASC'}
  end			
  
  # restrict to displaying the user's grants only
  def conditions_for_collection
    ['user_id = ?', session[:user].id ]
  end			

  # make sure we save the user id in the grant record to filter it
  def before_create_save(record)
    record.user_id = session[:user].id
  end

  # This is required for edge rails
  # protect_from_forgery :except => [:request_token, :access_token] if respond_to? :protect_from_forgery

  #before_filter :login_required, :except=>[:request_token,:access_token]

  # Step #1
  # First, OAuth consumer site connects here directly to get a request token pair
  # 
  # POST
  def request_token
    logger.debug "*** 1 OAUTH request_token"
    oauth_request=OAuth::Request.incoming(request)

    raise "Invalid Nonce" unless OauthNonce.remember(oauth_request.nonce,oauth_request.timestamp)

    # find the consumer      
    key = oauth_request.oauth_params[:oauth_consumer_key]

    # make sure it is registered and get its secret
    consumer  = Provider.find_by_consumer_key(key)
    raise "Unregistered Consumer" if consumer == nil

    secret  = consumer.consumer_secret 

    # verify the signature of the message
    raise "Invalid Signature" unless oauth_request.verify?(secret)

    provider_instance = ProviderInstance.new
    provider_instance.request_token  = rand(2**64)
    provider_instance.request_secret = rand(2**128)
    provider_instance.callback_url 	 = consumer.callback_url
    provider_instance.realm			 = oauth_request.realm

    consumer.provider_instances << provider_instance
    provider_instance.save!

    render :text => provider_instance.request_token_response
  rescue
    logger.error $!
    logger.error $!.backtrace.join("\n")
    render :text => "Fail: #{$!} #{params.to_yaml}"
  end

  # Step #2
  # First, OAuth consumer site redirects end-user here (carrying the request token pair, see #1)
  # End-user is asked for authorization, display YES/NO prompt
  # 
  # This request carries no OAuth params other than "oauth_token"
  # 
  def oauth_authorize
    logger.debug "*** 2 OAUTH Authorize: #{params.inspect}"

    @provider_instance = ProviderInstance.find_by_request_token(params[:oauth_token])
    raise "Invalid token" unless @provider_instance

    if params["oauth_callback"]
      @provider_instance.callback_url = params["oauth_callback"] 
    end

    @provider_instance.user_id		 = session[:user].id
    @provider_instance.access_token  = rand(2**64)   # not part of OAuth flow, we're using this field
    @provider_instance.access_secret = rand(2**128) # to confirm user has accepted
    @provider_instance.save!

    @provider = @provider_instance.provider
  rescue
    logger.error $!
    logger.error $!.backtrace.join("\n")
    render :text => "Fail: #{$!} #{params.to_yaml}"
  end

  # Step #3
  # End user has given his authorization, we will update our records before 
  # redirecting end user back to the OAuth consumer site
  # 
  # This request carries no OAuth params other than "oauth_token"
  # 
  def authorize_allow
    logger.debug "*** 3 OAUTH authorize_allow: #{params.inspect}"

    case params['commit']
    when 'Deny'
      redirect_to(@provider_instance.callback_url + "?" + "token=" + CGI.escape(params[:oauth_token]))

    when 'Allow'
      timing = params['timing']
      day    = params['day']
      month  = params['month']
      year   = params['year']

      case timing
      when 'forever'
        expiry	= "forever"
      when 'until'
        expiry = "#{month}/#{day}/#{year}"
      when 'once'
        expiry = 'once'
      end

      @provider_instance = ProviderInstance.find_by_request_token_and_access_token(params[:oauth_token], params[:access_token])
      raise "Invalid token" unless @provider_instance

      @provider_instance.access_token = params[:oauth_token]
      @provider_instance.expiry = expiry
      @provider_instance.save!

      logger.debug "Authorized: " + @provider_instance.to_yaml
      provider = @provider_instance.provider
      redirect_to(@provider_instance.callback_url + "?" + "token=" + CGI.escape(params[:oauth_token]))
    end
  rescue
    logger.error $!
    logger.error $!.backtrace.join("\n")
    render :text => "Fail: #{$!} #{params.to_yaml}"
  end

  # Step #4. 
  # Upon callback, OAuth consumer site connects here directly to exchange
  # the request_token for access_token. Access token is used for all 
  # subsequent API calls done on behalf of this end user.
  # 
  # POST 
  def access_token
    logger.debug "*** 4 OAUTH access_token: #{params.inspect}"
    oauth_request=OAuth::Request.incoming(request)

    # find the consumer      
    key = oauth_request.oauth_params[:oauth_consumer_key]

    # make sure it is registered and get its secret
    consumer  = Provider.find_by_consumer_key(key)
    raise "Unregistered Consumer" if consumer == nil

    secret  = consumer.consumer_secret 

    # verify the signature of the message
    #raise "Invalid Signature" unless oauth_request.verify?(secret)

    # find the instance
    oauth_token = oauth_request.token
    provider_instance = ProviderInstance.find(:first, :conditions => 
    ["request_token = ? AND access_token = request_token", oauth_token]
    ) || raise("Invalid auth token")

    # create an access token somehow
    provider_instance.access_token 	 = rand(2**64) 
    provider_instance.request_token  = nil
    provider_instance.request_secret = nil
    provider_instance.save!

    render :text => provider_instance.access_token_response
  rescue
    logger.error [params, @provider_consumer, $!.backtrace].to_yaml
    render :text => "#{$!}"
  end

end
