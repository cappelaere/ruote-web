#
#--
# Copyright (c) 2007-2008, John Mettraux, OpenWFE.org
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
# . Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.  
# 
# . Redistributions in binary form must reproduce the above copyright notice, 
#   this list of conditions and the following disclaimer in the documentation 
#   and/or other materials provided with the distribution.
# 
# . Neither the name of the "OpenWFE" nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
#++
#

#
# Made in Japan
#
# john.mettraux@openwfe.org
#

require "openid"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
  
class LoginController < ApplicationController

  layout "login"

   class InvalidOpenId < StandardError
   end

  class Result
    ERROR_MESSAGES = {
  	:missing    => "Sorry, the OpenID server couldn't be found",
  	:canceled   => "OpenID verification was canceled",
  	:failed     => "Sorry, the OpenID verification failed"
    }

    def self.[](code)
  	new(code)
    end

    def initialize(code)
  	@code = code
    end

    def ===(code)
  	if code == :unsuccessful && unsuccessful?
  	  true
  	else
  	  @code == code
  	end
    end

    ERROR_MESSAGES.keys.each { |state| define_method("#{state}?") { @code == state } }

    def successful?
  	@code == :successful
    end

    def unsuccessful?
  	ERROR_MESSAGES.keys.include?(@code)
    end

    def message
  	ERROR_MESSAGES[@code]
    end
  end
  
  def index

    session[:user] = nil

    if request.post?
      if using_open_id?
        open_id_authentication
      else
        @user = User.authenticate params[:name], params[:password]
      end
    
      if @user

        @user.neutralize
          # removes password information.
          # Maybe it'd be better to just store the user id.

        session[:user] = @user
        redirect_to :controller => "stores", :action => "index"
      else
        flash.now[:notice] = "Invalid user and/or password"
      end
    end
  end
  
  def logout

    session[:user] = nil
    flash[:notice] = "Logged out"

    redirect_to :action => "index"
  end

	def using_open_id?(identity_url = params[:openid_url]) #:doc:
	  !identity_url.blank? || params[:open_id_complete]
	end
	
	def open_id_complete
  	params[:open_id_complete] = true
	  # params[:action] = url_for :action=>'open_id_complete', :only_path => false
	  params.delete(:action)
	  open_id_authentication
  end
  
  protected
  def open_id_authentication
    # Pass optional :required and :optional keys to specify what sreg fields you want.
    # Be sure to yield registration, a third argument in the #authenticate_with_open_id block.

    authenticate_with_open_id(params[:openid_url], :required => [ :nickname, :email, :fullname ]) do |result, identity_url, registration|
      if result.successful?
        if !@user = User.find_by_identity_url(identity_url)
          @user = User.new(:identity_url => identity_url)
          assign_registration_attributes!(registration)
        end
        successful_login
      else
        #failed_login(result.message || "Sorry could not log in with identity URL: #{identity_url}")
      end
    end
  end

  # registration is a hash containing the valid sreg keys given above
   # use this to map them to fields of your user model
   def assign_registration_attributes!(registration)
     { :name => 'nickname', :email => 'email', :fullname=>'fullname' }.each do |model_attribute, registration_attribute|
       unless registration[registration_attribute].blank?
         @user.send("#{model_attribute}=", registration[registration_attribute])
       end
     end
     @user.save!
   end

  def authenticate_with_open_id(identity_url = params[:openid_url], fields = {}, &block) #:doc:
    if params[:open_id_complete].nil?
      begin_open_id_authentication(normalize_url(identity_url), fields, &block)
    else
      complete_open_id_authentication(&block)
    end
  end
  	
  def begin_open_id_authentication(identity_url, fields = {})
    begin
      open_id_response = timeout_protection_from_identity_server { 
        puts "begin_open_id_authentication: #{identity_url}"
        open_id_consumer.begin(identity_url) 
      }
    rescue OpenID::OpenIDError => e
      yield Result[:missing], identity_url, nil
      return
    end

    add_simple_registration_fields(open_id_response, fields)

    return_to = url_for :action => 'open_id_complete', :only_path => false
    realm = url_for :action => 'index', :only_path => false

    if open_id_response.send_redirect?(realm, return_to, params[:immediate])
      url = open_id_response.redirect_url(realm, return_to, params[:immediate])
      redirect_to url
    end		
  end
	
  def complete_open_id_authentication
    return_to  = url_for(:action => 'open_id_complete', :only_path => false)
    parameters = params.reject{ |k,v| request.path_parameters[k] }

    parameters.delete(:open_id_complete)

    open_id_response = timeout_protection_from_identity_server { open_id_consumer.complete(parameters, return_to) }
    identity_url     = normalize_url(open_id_response.identity_url) if open_id_response.identity_url

    case open_id_response.status
    when OpenID::Consumer::CANCEL
      yield Result[:canceled], identity_url, nil
    when OpenID::Consumer::FAILURE
      logger.info "OpenID authentication failed: #{open_id_response.message}"
      yield Result[:failed], identity_url, nil
    when OpenID::Consumer::SETUP_NEEDED
      logger.info "Immediate request failed - Setup Needed"
      yield Result[:failed], identity_url, nil 		 
    when OpenID::Consumer::SUCCESS
      sreg_resp = OpenID::SReg::Response.from_success_response(open_id_response)

      #yield Result[:successful], identity_url, open_id_response.extension_response('sreg')
      yield Result[:successful], identity_url, sreg_resp
    end      
	end
		
  def add_simple_registration_fields(open_id_response, fields)
    sregreq = OpenID::SReg::Request.new
 
	  sregreq.request_fields(['email','nickname', 'fullname'], true)
      # optional fields
      #sregreq.request_fields(['dob', 'fullname'], false)
 
	  open_id_response.add_extension(sregreq)
	  open_id_response.return_to_args['did_sreg'] = 'y'     	
  end
    
  def open_id_redirect_url(open_id_response)
    open_id_response.redirect_url(
        request.protocol + request.host_with_port + "/",
        open_id_response.return_to("#{request.protocol + request.host_with_port + request.path}?open_id_complete=1")
    )     
  end

  def timeout_protection_from_identity_server
    yield
  rescue Timeout::Error
    Class.new do
      def status
        OpenID::FAILURE
      end

      def msg
        "Identity server timed out"
      end
    end.new
  end
  
  # handle the openid server response
  def complete
     response = consumer.complete(params)

     case response.status
     when OpenID::SUCCESS

       @user = User.get(response.identity_url)

       # create user object if one does not exist
       if @user.nil?
         @user = User.new(:openid_url => response.identity_url)
         @user.save
       end

       # storing both the openid_url and user id in the session for for quick
       # access to both bits of information.  Change as needed.
       session[:user] = @user
       flash[:notice] = "Logged in as #{CGI::escape(response.identity_url)}"

       redirect_back_or_default('/')
       return

     when OpenID::FAILURE
       if response.identity_url
         flash[:notice] = "Verification of #{response.identity_url} failed."

       else
         flash[:notice] = 'Verification failed.'
       end

     when OpenID::CANCEL
       flash[:notice] = 'Verification cancelled.'

     else
       flash[:notice] = 'Unknown response from OpenID server.'
     end

     redirect_to :action => 'login'
  end
  
  private
  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default)
    session[:return_to] ? redirect_to_url(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end
  
  def successful_login
    session[:user] = @user
    redirect_back_or_default('/')
    flash[:notice] = "Welcome: #{@user.name}"
  end
   
  def normalize_url(url)
    begin
      uri = URI.parse(url)
      uri = URI.parse("http://#{uri}") unless uri.scheme
      uri.scheme = uri.scheme.downcase  # URI should do this
      uri.normalize.to_s
    rescue URI::InvalidURIError
      raise InvalidOpenId.new("#{url} is not an OpenID URL")
    end
  end
  
  # Get the OpenID::Consumer object.
  def open_id_consumer
    store = ActiveRecordStore.new
    consumer = OpenID::Consumer.new(session, store)
    return OpenID::Consumer.new(session, store)
  end
end

