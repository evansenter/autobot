$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "vienna_rna"
require "awesome_print"
require "resque"
require "autobot/helpers/data_loader_mysql_config"
require "autobot/jobs/fftx_jobs"

ViennaRna.debug = true

def alert_requirements
  puts "Minimum requirements:"
  ap({
    algorithm:   "...", 
    sequence:    "...", 
    structure:   "...", 
    description: "...", 
    data_from:   "..."
  })
end

def quick_run(options = {})
  unless options[:algorithm] && options[:sequence] && options[:structure] && options[:description] && options[:data_from]
    alert_requirements
  end
   
  Resque.enqueue(FftxDistributionFromSequenceAndStructureJob, options)
end

alert_requirements