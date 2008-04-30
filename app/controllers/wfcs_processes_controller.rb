require 'builder'
require 'lib/wfcs/utils'

class WfcsProcessesController < ApplicationController
  include Wfcs

  before_filter :check_ids
  
	active_scaffold :wf_process
  layout 'processes'

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

    # turn context_data into a Hash
    hash_str = gen_hash_str(context_data)

    @process = WfProcess.new( :definition_id=>@definition.id,
      :user_id      => user_id,
      :title        => title,
      :content      => content,
      :category     => category,
      :command      => command,
      :context_data => hash_str,
      :status       => "scheduled",
      :scheduled_at => Time.now.utc )
      
    @process.save!

    @wfid = submitFlow( user_id, @process.id, name, flow, context_data, command )
    @process.wfid = @wfid

    respond_to do |format|
      if @process.save!
        flash[:notice] = 'Workflow process was successfully created.'

        format.atom {
          #puts "*** created return head - atom"
          #head :created, :location => process_url(@process)+".atom"  

          # should not be necessary but only works with specific rails versions       	
          response.headers["Location"] = process_url(@process)

          xml = Builder::XmlMarkup.new(:indent => 2)
          @entry =  render_to_string :partial=>"feed/atom10_wfprocess_item", :locals => {:item => @process, :xm => xml }

          #render :status => :created, :location => process_url(@process), :content_type => "application/atom+xml"
          #render :atom does not work
          render :text => "<?xml version='1.0' ?>#{@entry}", :location => process_url(@process), :content_type => "application/atom+xml;type=entry"
        }

        format.xml  { 
          #puts "*** created return head - xml: #{process_url(@process)}"
          head :created, :location => process_url(@process)+".xml"
        }

        format.html { 
          #puts "*** created return head - html"
          #head :created, :location => process_url(@process)
          redirect_to process_url(@process)+".html"
        }
      end
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
  # turn context_data into a Hash
  def gen_hash_str(context_data)
    hash_str = ""
    if context_data
      context_data = context_data.to_hash
      context_data.each do |k,v|
        hash_str += "  <#{k}>#{v}</#{k}>\n"
      end
    end
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
      launchitem              = LaunchItem.new(flow)
      launchitem.user_id      = user_id
      launchitem.instance_id  = inst_id
      launchitem.flowname     = flowname
      launchitem.interval     = 0

      # all workflow parameters are in contextData
      if contextData
        contextData.each do |k,v|
          eval( "launchitem.#{k} = '#{v}'")
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
        flow_expression_id = $openwferu_engine.launch(launchitem)
      end

      @wfid   = flow_expression_id.wfid
    rescue Exception=>e
      raise "submitFlow exception"+ e.message + " " + e.backtrace.join("\n")
    end
  end

end