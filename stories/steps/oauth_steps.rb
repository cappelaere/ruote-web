#fixtures :oauth_grants

##
# Convenience function to get oauth and body in one hash to pass to post
#
def get_all_parameters
  h = Hash.new
  oauth_arr = @request['authorization'].split(", ")
  oauth_arr.each { |el| 
    arr = el.split("=")
    h[arr[0]] = CGI.unescape(arr[1].gsub(/\"/, ''))
  }
  
  params = @request.body
  if params
    #puts "parms body: #{params.inspect}"
    arr = params.split("=")
    h[arr[0]] = CGI.unescape(arr[1])
  end
  #y h.inspect
  h
end

##
# Convenience function to setup oauth
#
def setup_oauth( request_uri, xml=nil )

  @consumer = OAuth::Consumer.new(@client.key, @client.secret,
    { :site=> request_uri.scheme + "://"+ request_uri.host, 
      :http_method=>:post } 
    )

  @token = OAuth::AccessToken.new(@consumer, 'http://cappelaere.pip.verisignlabs.com/', nil)
  @request_parameters = { 'RAW_POST_DATA' => xml } if xml
  
  @request = Net::HTTP::Post.new(request_uri.path)
  @request.set_form_data( @request_parameters ) if xml
  
  @timestamp = Time.now.to_i.to_s
  @none      = Base64.encode64(OpenSSL::Random.random_bytes(32)).gsub(/\W/,'')
  
  @realm = '/wfcs'
  
  @token.sign!(@request, {:nonce => @nonce, :timestamp => @timestamp, :realm=>@realm})
    
end

steps_for( :oauth ) do
#  fixtures :oauth_grants
  
  When("user tries to create a new workflow") do
    post '/wfcs/workflows/'
  end
	
	When("user tries to create a new definition") do
    post '/wfcs/workflows/1/definitions'
  end
	
	When("user tries to create a new process") do
	  post '/wfcs/workflows/1/processes'    
  end
  
  When("user tries to update a workflow") do
	  put '/wfcs/workflows/1'  
  end
  
  When("user tries to update a definition") do
	  put '/wfcs/definitions/1'    
  end
  
  When("user tries to update a process") do
	  put '/wfcs/processes/1/'    
  end
  
  When("user tries to delete a workflow") do
	  delete '/wfcs/workflows/1'  
  end
  
  When("user tries to delete a definition") do
	  delete '/wfcs/definitions/1'    
  end
  
  When("user tries to delete a process") do
	  delete '/wfcs/processes/1'    
  end
  
  When("user registers client '$name'") do |name|
	  @session.post '/oauth/create', 
	    'client_application[name]'=>name, 
	    'client_application[url]'=>'http://test',
	    'client_application[callback_url]'=>'http://test',
	    'client_application[support_url]'=>'http://test'
	  #y @session.response.body
	  client = ClientApplication.find_by_name(name)
    assert client
	end
	
	Then("authorized user sees link '$name'") do |name|
	  #y @session.response.body
	  doc = Hpricot(@session.response.body)
	  link = doc.at('//a')
	  #y link.inspect
	  assert_equal name, link.inner_html
    
  end
  
  Then("authorized user does not see link '$name'") do |name|
	  #y @session.response.body
	  doc = Hpricot(@session.response.body)
	  link = doc.at('//a')
	  #y link.inspect
	  assert_equal 'OAuth', link.inner_html
  end
  
  
  When("user grants access to client '$name' realm '$realm'") do |name, realm|
    @client = ClientApplication.find_by_name(name)
    assert @client
	  if @client
	    @session.post '/oauth/grants',
	      'record[client_name]'=>name,
	      'record[realm]'=>realm
	    	
	    grant = OauthGrant.find_by_client_application_id(@client.id)
	    assert grant
	  end
	end
	
	Then("the user can create a new workflow") do
	  xml = "<?xml version='1.0' encoding='UTF-8'?>"
    xml += "<entry xmlns='http://www.w3.org/2005/Atom'>"
    xml += "  <title>new workflow</title>"
    xml += "  <updated>2003-12-13T18:30:02Z</updated>"
    xml += "  <author><name>alice</name></author>"
    xml += "  <content>example</content>"
    xml += "</entry>"
    
    request_uri = URI.parse('http://www.example.com/wfcs/workflows.atom')
  
    setup_oauth( request_uri, xml )
   
    post request_uri.path, get_all_parameters
    
    assert_equal 201, status
	end
	
	Then("the user can publish the workflow") do

	  xml = "<?xml version='1.0' encoding='UTF-8'?>"
    xml += "<entry xmlns='http://www.w3.org/2005/Atom' xmlns:g='http://wfxml.wfmc.org'>"
    xml += "  <title>new workflow</title>"
    xml += "  <g:published>1</g:published>"
    xml += "</entry>"
    
    request_uri = URI.parse('http://www.example.com/wfcs/workflows/new-workflow.atom')
   
    setup_oauth( request_uri, xml )
        
    put request_uri.path, get_all_parameters
    assert_equal 200, status
    #y "put #{request.body}"

  end
  
	Then("the user can get the workflow") do
    request_uri = URI.parse('http://www.example.com/wfcs/workflows/new-workflow.atom')
    setup_oauth( request_uri )
    get request_uri.path, get_all_parameters
    
    #y "get #{request.body}"
    # make sure we get an entry
	  doc = Hpricot(response.body)
    entry = doc.at('entry')
	  assert_not_nil  entry 
	  
    assert_equal 200, status
  
    # check content-type
    assert_equal 'application/atom+xml', response.content_type  
    
  end
  
	Then("the user can delete the workflow") do
    request_uri = URI.parse('http://www.example.com/wfcs/workflows/new-workflow.atom')
    setup_oauth( request_uri )
    delete request_uri.path, get_all_parameters
    assert_equal 200, status
  end

end