# VERBOSE=true COUNT=4 QUEUE=* rake resque:workers

require "resque/tasks"
Dir["./lib/autobot/jobs/*.rb"].each { |job_file| require job_file }
