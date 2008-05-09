require File.dirname(__FILE__) + "/helper"

with_steps_for(:test) do
  run_local_story "test_story", :type=> RailsStory
end
