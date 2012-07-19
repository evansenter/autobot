require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/data_loader_mysql_config.rb"
require "./../jobs/fftbor_jobs.rb"

ViennaRna.debug = false

results_directory = ARGV[0]
data_from         = ARGV[1]

if (results_directory && data_from)
  Dir[File.join(results_directory, "*.log")].each do |log_path|
    Resque.enqueue(DataLoaderJob, { log_path: log_path, data_from: data_from })
  end
else
  puts "ruby ./data_loader.rb RESULTS_DIRECTORY DATA_FROM"
  puts "  RESULTS_DIRECTORY: location of .log output files"
  puts "  DATA_FROM:         metadata for fftbor_data distributions table data_from column"
end