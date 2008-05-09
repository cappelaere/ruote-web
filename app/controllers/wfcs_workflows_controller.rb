require 'builder'
require 'date'
require 'lib/wfcs/utils'

class WfcsWorkflowsController < ApplicationController

  include Wfcs

  active_scaffold :workflows

  layout 'workflows'

  before_filter :login_or_oauth_required, :only=>[:create, :edit, :update, :destroy, :show]

  def index
    @items = Workflow.find(:all, :conditions=>["published=1"])
    respond_to do |format|
      format.html { redirect_to :action=>'list', :format=>'html' }
      format.xml  { redirect_to :action=>'list', :format=>'xml' }
      format.atom { generate_atom_feed }
      format.metadata { 
        obj = Workflow.find(:first)
        render :xml => metadata(obj), :content_type => Mime::XML, :status => 200    
      }
    end
  end

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
  # workflow update
  #
  def update
    check_workflow_id( :id )
    begin
      @record = Workflow.find(params[:id])
    rescue Exception=>e 
      return redirect_to(:text=>"Invalid workflow: #{params[:id]}", :status=>'500')
    end

    begin
      xml     = params[:raw_post_data]
      xml     = params['RAW_POST_DATA']  if xml == nil
      xml     = request.env["RAW_POST_DATA"]  if xml == nil
      user_id = session[:user].id

      @entry  = REXML::Document.new( xml )

      @record.title       = @entry.root.elements["//title"] ? @entry.root.elements["//title"].text : @record.title
      @record.content     = @entry.root.elements["//content"] ? @entry.root.elements["//content"].text : @record.content
      @record.category    = @entry.root.elements["//category"] ? @entry.root.elements["//category"].attributes["term"] : @record.category
      @record.permission  = @entry.root.elements["//g:permission"] ? @entry.root.elements["//g:permission"].text : @record.permission
      @record.published   = @entry.root.elements["//g:published"] ? @entry.root.elements["//g:published"].text : @record.published
      @record.user_id     = user_id
      @record.save!
      
    rescue Exception=>e
      return redirect_to( :text=>"Invalid workflow: #{parms[:id]} -- #{e}", :status=>'500' )
    end
  end

  ##
  # destroy worflow
  #
  def destroy
    check_workflow_id( :id )
    begin
      @record = Workflow.find(params[:id])
    rescue Exception=>e 
      return redirect_to( :text=>"Invalid workflow: #{params[:id]}", :status=>'500' )
    end

    begin
      @record.destroy
    rescue Exception=> e
      return redirect_to( :text=>"Error deleting workflow -- #{e}", :status=>'500' )
    end

    respond_to do |format|
      format.atom { 
        render :xml=>"<delete successful>", :layout=>false
      }

      format.xml  { 
        render :xml=>"<delete successful>", :layout=>false
      }

      format.html { }
    end
  end

  ##
  # show workflow
  def show
    
    check_workflow_id( :id )
    begin
      @record = Workflow.find(params[:id])
    rescue Exception=>e 
      return redirect_to( :text=>"Invalid workflow: #{params[:id]}", :status=>'500' )
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

  private

  def generate_atom_feed
    @feed_title = "Worflow Feed"
    @today = Date.today
    render :action=>'atom_feed', :layout=>false
  end

end