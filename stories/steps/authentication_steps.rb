steps_for(:authentication) do
  
  Given("anonymous user") do
    @session = nil
  end
  
	When("user accesses '$page'") do |page|
    get page
  end
  
	Then("the status should be $value") do |value|
	  if @session
  	  assert_equal value.to_i, @session.status
	  else
	    assert_equal value.to_i, status
	  end
  end
	
	Given("an authorized user named: '$name' and password: '$password'") do |name, password|
    @name = name
    @password = password
    
    open_session do |session|
	    session.post "/login", :name=>@name, :password=>@password
	    session.follow_redirect!
      assert_equal 200, session.status
      @session = session
    end
  end
  
	When("authorized user accesses '$page'") do |page|
    @session.get page   
  end

	Given("a user with openid: '$openid'") do |openid|
    open_session do |session|
	    session.post "/login", :openid_url=>openid
      assert_equal 200, session.status
      @session = session
    end
  end

end