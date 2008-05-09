steps_for( :test ) do
  
  Given("anonymous user") do
    #@session = nil
  end
  
	When("user tries this") do 
    get "/wfcs/workflows.xml"  
    y "status #{status}" 
  end
  
	Then("the status should be $value") do |value|
	  #assert_equal value.to_i, status
  end
  
end
