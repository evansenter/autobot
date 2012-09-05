require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/data_loader_mysql_config.rb"
require "./../jobs/fftbor_jobs.rb"

ViennaRna.debug = false

def alert_requirements
  puts "Minimum requirements:"
  ap({
    sequence:    "...", 
    structure:   "...", 
    description: "...", 
    data_from:   "..."
  })
end

def quick_run(options = {})
  alert_requirements unless options[:sequence] && options[:structure] && options[:description] && options[:data_from]
  Resque.enqueue(FftborDistributionJob, options)
end

alert_requirements