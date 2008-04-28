require 'rubygems'
require 'hpricot'

steps_for(:wfcs_discovery) do

	Then("service document link is in the headers") do
    doc  = Hpricot(response.body)
    @link = doc.at("/html/head/link[@type='application/atomsvc+xml']")
    assert @link
  end
  
  Then("service document link is valid") do
    href = @link.attributes['href']
	  get href
	  
	  @service_document =  response.body

	  #make sure the page exists
    assert_equal 200, status
	end

	Then("content-type is application/atomsvc+xml") do
    # make sure the content-type is proper
    assert_equal 'application/atomsvc+xml', response.content_type  
  end  
	
	Then("collection links are valid") do
    doc = Hpricot(@service_document)
    doc.search('//collection').each do |col|
      href = col.attributes['href']
      get href
      assert_equal 200, status
    end
  end
  
end