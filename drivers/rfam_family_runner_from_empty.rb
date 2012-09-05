require "vienna_rna"
require "awesome_print"
require "resque"
require "./../jobs/fftbor_jobs.rb"

Rbfam.script("sequences_in_mysql")

(family         = Rbfam::Family.new(ARGV[0])).load_entries!
ViennaRna.debug = false

family.entries.each do |rfam|
  Resque.enqueue(FftborDistributionFromEmptyJob, {
    sequence:    rfam.sequence, 
    description: rfam.description, 
    data_from:   "rfam", 
    options: { 
      family: "#{family.family_name} empty"
    }
  })
end
