require 'builder'
require 'lib/wfcs/utils'
require 'openwfe'

class WfcsProcessesController < ApplicationController
  include Wfcs

  layout 'processes'

  before_filter :login_or_oauth_required, :only=>[:create, :edit, :update, :destroy]
  before_filter :check_ids, :only=>[:create, :edit, :update]
  
	active_scaffold :wf_process

  active_scaffold :wf_process do |config|
     config.label = "Processes Entries"
     config.columns = [ :id, :title, :content, :category, :context_data, :result_data, :command, :created_at, :updated_at, :scheduled_at, :status, :wfid, :login]

     list.sorting = {:updated_at => 'DESC'}
  end
   
  def index
    ##
    # TODO restrict to what you can see
    @items = WfProcess.find(:all)
    respond_to do |format|
     format.html { redirect_to :action=>'list', :format=>'html' }
     format.xml  { redirect_to :action=>'list', :format=>'xml' }
     format.atom { generate_atom_feed }
     format.metadata { 
        obj = WfProcess.find(:first)
        render :xml => metadata(obj), :content_type => Mime::XML, :status => 200    
     }
    end
  end

  ##
  # Show process information
  #def show
  #end
  
  ##
  # Create a new process
  def create
    xml = params[:raw_post_data]
    xml = params[:RAW_POST_DATA]  if xml == nil
    xml = request.env["RAW_POST_DATA"]  if xml == nil

    user_id = session[:user].id

    ## TODO
    # Check for permission here    
    
    @wfid = -1

    if !@definition
      raise "No @definition nor raw_post_data!!!!"
    end

    flow = @definition.openwfe

    if params[:data] # xforms
      data          = params[:data]
      entry         = data['entry']
      title         = entry['title']
      content       = entry['content']
      category      = entry['category']
      command       = entry['command']
      context_data  = entry['context_data']

    elsif xml   #POST
      begin
        @entry = REXML::Document.new( xml )

        title   = @entry.root.elements["//title"] ? @entry.root.elements["//title"].text : "title"
        content = @entry.root.elements["//content"] ? @entry.root.elements["//content"].text : ""
        category= @entry.root.elements["//category"] ? @entry.root.elements["//category"].attributes["term"] : ""

        type    = @entry.root.elements["//g:item_type"] ? @entry.root.elements["//g:item_type"].text : "processes" 
        if type  != "processes"
          raise "invalid collection name: #{type}"
        end

        command      = @entry.root.elements["//g:command"].text
        context_data = @entry.root.elements["//g:context_data"] ? @entry.root.elements["//g:context_data"] : nil 

      rescue Exception => e
        return exception_report( e )
      end
    else
      raise "no xml available"
    end

    context_data = context_data.to_hash

    @process = WfProcess.new( :definition_id=>@definition.id,
      :user_id      => user_id,
      :title        => title,
      :content      => content,
      :category     => category,
      :command      => command,
      :context_data => to_xml(context_data),
      :status       => "scheduled",
      :scheduled_at => Time.now.utc )
      
    @process.save!

    @wfid = submitFlow( user_id, @process.id, title, flow, context_data, command )
    @process.wfid = @wfid

    respond_to do |format|
      if @process.save!
        flash[:notice] = 'Workflow process was successfully created.'

        format.atom { 
          head :created, :location => process_url(@process)+".atom"
        }

        format.xml  { 
          head :created, :location => process_url(@process)+".xml"
        }

        format.html { 
          redirect_to process_url(@process)+".html"
        }
      end
    end
  end

  def results
     id = params[:id]
     process = WfProcess.find(id)
     xml = process.result_data
     if xml == nil
       render :xml=>"<result_data>NOT AVAILABLE YET</result_data>"
     else    
       render :xml=>"<result_data>#{xml}</result_data>"
     end
   end
   
  private

  def generate_atom_feed
    @feed_title = "Process Feed"
    @today = Date.today
    @items = WfProcess.find(:all)
    render :action=>'atom_feed', :layout=>false
  end
  
  ##
  # turn context_data Hash into XML
  def to_xml(context_data)
    hash_str = ""
    if context_data
      context_data.each do |k,v|
        hash_str += "  <#{k}>#{v}</#{k}>\n"
      end
    end
    hash_str
  end

  ##
  # Get the workflow if and definition id
  def check_ids
    if params[:workflow_id]
      check_workflow_id( :workflow_id)
      @workflow = Workflow.find(params[:workflow_id]) 
    end

    if params[:definition_id] 	
      check_definition_id(:definition_id) 
      @definition = Definition.find(params[:definition_id])
    else
      if @workflow
        @definition= Definition.find(:first, :conditions=>["workflow_id=? AND status='enabled'", @workflow.id], :order=>"updated_at ASC" )
      end
    end
    true
  end
  
  #
  # Submit workflow to the engine with the proper options and context
  # 
  def submitFlow( user_id, inst_id, flowname, flow, contextData, cmd_options )
    begin
      launchitem              = OpenWFE::LaunchItem.new(flow)
      launchitem.user_id      = user_id
      launchitem.instance_id  = inst_id
      launchitem.flowname     = flowname
      launchitem.interval     = 0

      # all workflow parameters are in contextData
      if contextData
        puts "submitFlow contextData: #{contextData}"
        contextData.each do |k,v|
          puts( "launchitem.#{k} = '#{v}'")
          eval( "launchitem.#{k} = '#{v}'")  if v && k
        end
      end

      # check cmd_options
      if cmd_options.index("in ") 
        cmd_options.gsub!("in ", "")
        flow_expression_id = $openwferu_engine.launch(launchitem, :in=>cmd_options)

      elsif cmd_options.index("at ")
        cmd_options.gsub!("at ", "")
        launchitem.next_scheduled_time = cmd_options
        flow_expression_id = $openwferu_engine.launch(launchitem, :at=>cmd_options)

      elsif cmd_options.index("cron ")
        cmd_options.gsub!("cron ", "")
        flow_expression_id = $openwferu_engine.launch(launchitem, :cron=>cmd_options)

      elsif cmd_options.index("every ")
        cmd_options.gsub!("every ", "")
        launchitem.interval            = cmd_options
        flow_expression_id = $openwferu_engine.launch(launchitem, :every=>cmd_options)

      else
        puts "launchitem: #{launchitem.inspect}"
        flow_expression_id = $openwferu_engine.launch(launchitem)
      end

      @wfid   = flow_expression_id.wfid
    rescue Exception=>e
      raise "submitFlow exception"+ e.message + " " + e.backtrace.join("\n")
    end
  end

end

class REXML::Element
  def to_hash(default_hash = {})
    convert_node_to_hash(self, default_hash)
  end
  
  protected
    def convert_node_to_hash(node, hash)
      node.elements.each do |elm|
        hash[elm.name] = elm.elements.empty? ? elm.text : convert_node_to_hash(elm, hash)
      end
      puts "*** context_data hash: #{hash.inspect}"
      return hash
    end
end