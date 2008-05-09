require File.dirname(__FILE__) + "/helper"
require File.dirname(__FILE__) + "/../spec/spec_helper.rb"

with_steps_for(:oauth, :authentication) do
  run_local_story "oauth_story", :type=> RailsStory
end
