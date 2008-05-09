require 'builder'
require 'date'
require 'lib/wfcs/utils'

class WfcsDefinitionsController < ApplicationController

  include Wfcs
  active_scaffold :definitions
  
  layout 'definitions'
  
  before_filter :login_or_oauth_required, :only=>[:create, :edit, :update, :destroy]

  active_scaffold :definition do |config|
     config.label = "Workflow Definitions"
     config.list.columns = [ :workflow, :version, :login , :created_at, :updated_at, :xpdl, :openwfe, :status, :flow, :xform, :template]
     #list.columns.exclude :comments
     #list.sorting = {:updated_at => 'DESC'}
  end
   
  ##
  # Generic index
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
  # Create a new definition
  def create
    xml = params[:raw_post_data]
    xml = params['RAW_POST_DATA']  if xml == nil
    xml = request.env["RAW_POST_DATA"]  if xml == nil
    user_id = session[:user].id
    begin
      @entry = REXML::Document.new( xml )

      title   = @entry.root.elements["//title"] ? @entry.root.elements["//title"].text : "title"
      content = @entry.root.elements["//content"] ? @entry.root.elements["//content"].text : ""
      category= @entry.root.elements["//category"] ? @entry.root.elements["//category"].attributes["term"] : ""
      permission = @entry.root.elements["//g:permission"] ? @entry.root.elements["//g:permission"].text : ""

      type    = @entry.root.elements["//g:item_type"] ? @entry.root.elements["//g:item_type"].text : "workflows" 
      if type  != "workflows"
        raise "invalid collection name: #{type}, expecting 'workflows'"
      end

      wf = Workflow.new( :title=>title, :content=>content, :category=>category, :user_id=> user_id, 
      :permission=>permission, :published => 0)

      respond_to do |format|
        if wf.save!
          flash[:notice] = 'Workflow process was successfully created.'

          format.atom { 
            head :created, :location => workflow_url(wf)+".atom"
          }

          format.xml  { 
            head :created, :location => workflow_url(wf)+".xml"
          }

          format.html { 
            redirect_to workflow_url(wf)+".html"
          }
        end
      end
    rescue Exception => e
      logger.debug "exception #{e}"
    end
  end
  
  ##
  # show definition
  def show
    #check_workflow_id( :id )
    begin
      @record = Definition.find(params[:id])
    rescue Exception=>e 
      return redirect_to( :text=>"Invalid definition: #{params[:id]}", :status=>'500' )
    end   
    
    respond_to do |format|
      format.atom { 
        render :action=>'atom_entry', :layout=>false
      }
      
      format.xml { 
        render :action=>'atom_entry', :layout=>false
      }

      format.html { }
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
      begin
        str = IO.read(filestr)
        doc = REXML::Document.new( str )
        entry = REXML::XPath.first(doc,'//entry' )
        xml = "<?xml version='1.0'?>\n"
        entry.attributes['xmlns']="http://www.w3.org/2005/Atom"
        entry.attributes['xmlns:g']="http://geopbms/1.0"

        xml += entry.to_s
        render :xml=>xml
      rescue Exception=>e
        render :text=>"Error: #{e}"
      end
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
        render :file=>filestr, :content_type => "application/xml"
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