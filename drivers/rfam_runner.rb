require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/data_loader_mysql_config.rb"
require "./../jobs/fftx_jobs.rb"

ViennaRna.debug = false

Distribution.where("data_from = 'rfam' AND sequence_length = 300").select { |distribution| distribution.structure =~ /^\.+$/ }.each do |rfam|
  Resque.enqueue(FftborDistributionJob, {
    sequence:    rfam.sequence, 
    structure:   rfam.structure, 
    description: rfam.description, 
    data_from:   rfam.data_from, 
    options: { 
      family: rfam.family 
    }
  })
end