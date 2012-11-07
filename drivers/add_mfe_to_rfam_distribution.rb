require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/data_loader_mysql_config.rb"
require "./../jobs/fftx_jobs.rb"

family = Rbfam::Family.new(ARGV[0])

Distribution.find_in_batches(conditions: "family LIKE '#{family.family_name}%' AND mfe IS NULL") do |group|
  group.each do |distribution|
    Resque.enqueue(AddMfeToDistributionJob, id: distribution.id)
  end
end