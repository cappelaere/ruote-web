module Wfcs

  ##
  # WfXML Handler
  # 
  def exceptionHandler( e )

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.Fault do
      xml.faultCode   e.to_s
      xml.faultString e.message
      xml.detail do
        xml.ErrorCode    e,to_s
        xml.ErrorMessage e.backtrace.join("\n")
      end
    end
  end

  ##
  # Allow to pass id or names
  # 
  def check_workflow_id( key )
    id = params[key]
    if id.to_i.to_s != id
      obj = Workflow.find_by_title(id)
      if obj
        params[key] = obj.id
      end
    end
  end

  ##
  # Check definition version
  #
  def check_definition_id( key )
    id = params[key]
    if id.to_i.to_s != id
      obj = Definition.find_by_version(id)
      if obj
        params[key] = obj.id
      end
    end
  end

  ##
  # Metadata output of a resource collection
  # 
  def metadata( obj  )
    klass_name = obj.class.to_s

    collection = klass_name.downcase.pluralize
    collection = 'processes' if collection == 'wfprocesses'

    today = DateTime.now
    @columns = eval("#{klass_name}.columns")

    xml = Builder::XmlMarkup.new(:indent => 2)
    xml.instruct!
    xml.entry :xmlns => "http://www.w3.org/2005/Atom", 'xmlns:gm' => "http://base.google.com/ns-metadata/1.0" do
      xml.id   url_for(:only_path => false, :controller => "/wfcs/#{collection}", :action=>"index" )
      xml.updated today.strftime("%Y-%m-%dT%H:%M:%SZ") 
      xml.category :scheme=>url_for(:only_path => false, :controller => "/wfcs/#{collection}", :action=>"index" ), :term=>"#{collection}"
      xml.tag!("title", :type=>'text') do
        xml.text! collection
      end
      xml.tag!("content", :type=>'text') do
        xml.text! collection
      end

      xml.tag!( "gm:item_type", 'xmlns:gm' => "http://base.google.com/ns-metadata/1.0") do
        xml.text! collection
      end

      xml.tag!("gm:attributes") do
        @columns.each do |col, attrs|
          xml.tag!( 'gm:attribute', :name=>col.name, :type=>col.type.to_s)
        end
      end
    end
  end
end