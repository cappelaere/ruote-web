
#$LOAD_PATH << "~/openwfe-ruby/lib"
#$LOAD_PATH << "vendor/openwfe-ruby/lib"
$LOAD_PATH << "../ruote/lib"

require 'rubygems'

#
# the workflow engine
#

require 'densha/engine' # lib/densha/engine.rb

require 'openwfe/extras/misc/activityfeed' # gem 'openwferu-extras'

require 'json' # gem 'json_pure'

#
# adding the dev_data if necessary

if $0 =~ /script\/server/ and RAILS_ENV == 'development'

  users = User.find(:all)

  require 'db/dev_data' if users.size < 1
end

#
# instantiates the workflow engine

#require 'logger'

ac = {}

ac[:work_directory] = "work_#{RAILS_ENV}"
  #
  # where the workflow engine stores its rundata
  #
  # (note that workitems are stored via ActiveRecord as soon as they are
  #  assigned to an ActiveStoreParticipant)

ac[:logger] = Logger.new("log/openwferu_#{RAILS_ENV}.log", 10, 1024000)
ac[:logger].level = if RAILS_ENV == "production" 
  Logger::INFO
else
  Logger::DEBUG
end

ac[:ruby_eval_allowed] = true
  #
  # the 'reval' expression and ${r:xxx} notation are allowed

ac[:dynamic_eval_allowed] = true
  #
  # the 'eval' expression is allowed


$openwferu_engine = Densha::Engine.new ac

$openwferu_engine.reload_store_participants
  #
  # reload now.
  #
  # will register a participant per workitem store


#
# init the Atom activity feed

$openwferu_engine.init_service(
    'activityFeedService', OpenWFE::Extras::ActivityFeedService)


at_exit do
  #
  # make sure to stop the workflow engine when 'densha' terminates

  $openwferu_engine.stop
end

#
# add your participants there

require 'config/openwferu_participants'

