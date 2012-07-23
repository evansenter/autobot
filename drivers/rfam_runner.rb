require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/data_loader_mysql_config.rb"
require "./../jobs/fftbor_jobs.rb"

ViennaRna.debug = false
Distribution.connect

Distribution.where("data_from = 'rfam' AND sequence_length = 300 AND structure REGEXP '^\\.*$'").each do |rfam|
  Resque.enqueue(FftborDistributionJob, {
    sequence:    rfam.sequence, 
    structure:   "." * rfam.sequence_length, 
    description: rfam.description, 
    data_from:   rfam.data_from, 
    options: { 
      family: rfam.family 
    }
  })
end