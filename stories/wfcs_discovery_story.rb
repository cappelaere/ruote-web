require File.dirname(__FILE__) + "/helper"

with_steps_for(:wfcs_discovery, :authentication) do
  run_local_story "wfcs_discovery_story", :type=> RailsStory
end
