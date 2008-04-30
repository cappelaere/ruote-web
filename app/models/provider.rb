class Provider < ActiveRecord::Base

  has_many :provider_instances, :dependent => :destroy
  belongs_to :oauth_site, :polymorphic => true

  validates_uniqueness_of :consumer_key

  @instance_klass = ProviderInstance 
  @instances_method = @instance_klass.name.tableize
  @instance_parent_method = self.name.tableize.singularize

  #def before_create
  #  begin
  #    self.consumer_key = rand(2**64)
  #    self.consumer_secret = rand(2**128)
  #  end while !self.valid?
  #end  

  def self.find_or_build_instance(controller, oauth_request)
    #puts "*** find_or_build_instance oauth_request: #{oauth_request.oauth_params.inspect}"
    oauth_token = oauth_request.token
    if !oauth_token.blank?
      instance = @instance_klass.find(:first, :conditions => 
      ["request_token = ? AND access_token = request_token", oauth_token]
      ) || raise("Invalid token")
      provider = instance.send(@instance_parent_method)
    else
      oauth_consumer_key = oauth_request.oauth_params[:oauth_consumer_key]
      provider = self.find_by_consumer_key(oauth_consumer_key) || raise("Invalid Consumer Key")
      instance = provider.send(@instances_method).build
    end

    @consumer = OAuth::Consumer.new(
    provider.consumer_secret, 
    provider.consumer_key, 
    provider.callback_url, 
    controller.url_for(:controller => controller, :action => "request_token", :id => "oauth"), 
    controller.url_for(:controller => controller, :action => "authorize", :id => "oauth"), 
    controller.url_for(:controller => controller, :action => "access_token", :id => "oauth"), 
    instance.request_token,
    instance.request_secret)

    this_url = "#{controller.request.protocol}#{controller.request.host_with_port}#{controller.request.request_uri}"
    @consumer.signature_base_string = @consumer.get_signature_base_string(
    controller.request.method.to_s.upcase, 
    URI.parse(this_url), 
    (oauth_header = ""), 
    controller.params.reject {|k,v| ["action", "controller", "id"].include?(k)}
    )
    signer = OAuth::Signer.new(controller.params["oauth_signature_method"])
    signature = signer.sign(@consumer.signature_base_string, @consumer.signing_key)
    raise "Invalid signature" unless signature == controller.params["oauth_signature"]

    return instance
  end  
end
