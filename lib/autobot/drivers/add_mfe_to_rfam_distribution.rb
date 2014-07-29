$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/helpers/data_loader_mysql_config"
require "autobot/jobs/fftx_jobs"

family = Rbfam::Family.new(ARGV[0])

Distribution.find_in_batches(conditions: "family LIKE '#{family.family_name}%' AND mfe IS NULL") do |group|
  group.each do |distribution|
    Resque.enqueue(AddMfeToDistributionJob, id: distribution.id)
  end
end