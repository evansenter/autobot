require "vienna_rna"
require "awesome_print"
require "resque"
require "./../jobs/fftbor_jobs.rb"

Rbfam.script("sequences_in_mysql")

rfam_sequences  = SequenceTable.where(extended: false)
ViennaRna.debug = false

rfam_sequences.each do |rfam|
  Resque.enqueue(FftborDistributionJob, {
    sequence:    rfam.sequence, 
    structure:   ViennaRna::Fold.run(rfam.sequence).structure, 
    description: ("%s %s %s" % [rfam.accession, rfam.seq_from, rfam.seq_to]).gsub(/[^A-Za-z0-9]/, "_"), 
    data_from:   "rfam", 
    options: { 
      family: rfam.family 
    }
  })
end
