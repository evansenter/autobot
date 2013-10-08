$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "vienna_rna"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

(0...1000).each do |i|
  Resque.enqueue(EnergyGridFromStructureFile, {
    seq_file: "/Users/evansenter/Data/MFPT Kinetics/synthetic_seq_files/seq_%03d.fa" % i,
    str_file: "/Users/evansenter/Data/MFPT Kinetics/all_structures_per_synthetic_seq/structures_for_seq_%03d.txt" % i,
    out_file: "/Users/evansenter/Data/MFPT Kinetics/actual_energy_grids_for_synthetic_seq/energy_grid_%03d.csv" % i
  })
end