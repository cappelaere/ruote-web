require 'builder'
require 'date'
require 'lib/wfcs/utils'

class WfcsDefinitionsController < ApplicationController

  include Wfcs
  active_scaffold :definitions
  layout 'definitions'

  active_scaffold :definition do |config|
     config.label = "Workflow Definitions"
     config.list.columns = [ :workflow, :version, :login , :created_at, :updated_at, :xpdl, :openwfe, :status, :flow, :xform]
     #list.columns.exclude :comments
     #list.sorting = {:updated_at => 'DESC'}
  end
   
  def index
    @items = Definition.find(:all)

    respond_to do |format|
      format.html { redirect_to :action=>'list', :format=>'html' }
      format.xml  { redirect_to :action=>'list', :format=>'xml' }
      format.atom { generate_atom_feed }

      format.metadata {  
        obj = Definition.find(:first)
        render :xml => metadata(obj), :content_type => Mime::XML, :status => 200    
      }
    end
  end


  ##
  # Generate a POST Template for that workflow definition
  #
  def template
    id = params[:id]
    @current_user = session[:user]
    @definition = Definition.find(id)
    xform = @definition.xform
    xform = 'default.xform' if xform == ''
    filestr = "#{RAILS_ROOT}/public/xforms/#{xform}"
    if File.exists?(filestr)
      str = IO.read(filestr)
      doc = REXML::Document.new( str )
      entry = REXML::XPath.first(doc,'//entry' )
      xml = "<?xml version='1.0'?>\n"
      entry.attributes['xmlns']="http://www.w3.org/2005/Atom"
      entry.attributes['xmlns:g']="http://geopbms/1.0"

      xml += entry.to_s
      render :xml=>xml
    end 
  end

  ##
  # Display the OpenWFE
  # TODO: Graphical Representation
  #
  def openwfe
    id = params[:id]
    @definition = Definition.find(id)
    @defurl = ''
    begin
      #
      # reading the process definition, if possible...

      @process_definition, @json_process_definition = load_process_definition

    rescue Exception => e

      return :text=> "couldn't parse process definition #{id}"
    end

    #@from_launch = request.env['HTTP_REFERER'].match("/launchp$")
    #@from_launch = request.env['HTTP_REFERER']

    @is_xml = @process_definition.strip[0, 1] == "<"

    render :layout=>'densha'
  end

  ##
  # Display the XPDL
  #
  def xpdl
    id = params[:id]
    @definition = Definition.find(id)
    @defurl = ''
    @from_launch = false
    begin
      #
      # reading the process definition, if possible...

      @process_definition, @json_process_definition = [ @definition.xpdl, nil]

    rescue Exception => e

      return :text=> "couldn't parse process definition #{id}"
    end

    #@from_launch = request.env['HTTP_REFERER'].match("/launchp$")
    #@from_launch = request.env['HTTP_REFERER']

    @is_xml = @process_definition.strip[0, 1] == "<"

    render :action=>'openwfe', :layout=>'densha'
  end

  ##
  # Display the flow diagram if we have one
  #
  def flow
	  id = params[:id]
	  entry = Definition.find(id)
	  link  = entry.link
	  
	  if link
	    @file = "/images/workflows/#{link}"
	  else
	    @file = "/images/workflows/under_construction.jpg"
	  end
	 end
	 
  ##
  # Display the XForm
  #
  def xform

    id = params[:id]

    @current_user = session[:user]
    #@workflow   = Workflow.find( id )
    @definition = Definition.find(id)

    #if not current_user.authorized? @workflow.permission
    #
    # preventing URLs from being fed directly to the webapp

    #  flash[:notice] = "not authorized to launch : #{defurl}"

    #  redirect_to :controller => "/"
    #  return
    #end

    begin
      xform   = @definition.xform
      filestr = "#{RAILS_ROOT}/public/xforms/#{xform}"
      #check if we have an xform
      if xform.size>0 && File.exists?(filestr)
        #@html = IO.read(filestr)
        #render :partial=>"xforms", :layout=>false
        #render :file=>filestr, :content_type => "application/xhtml+xml"
        render :file=>filestr, :content_type => "application/xml"
        #xml = IO.read(filestr)
        #render :xml=>xml
      end

      # otherwise use the default lauch capability
    rescue Exception => e
      flash[:notice] = "failed to launch : #{e.to_s}"
      raise e
    end
  end


  private
  def load_process_definition

    pdef = @definition.openwfe
    prep = OpenWFE::DefParser.parse pdef

    [ pdef, prep ]
  end

  def generate_atom_feed
    @feed_title = "Worflow Feed"
    @today = Date.today
    render :action=>'atom_feed', :layout=>false
  end

end