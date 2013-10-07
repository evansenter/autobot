$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "vienna_rna"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

Dir["/Users/evansenter/Data/MFPT Kinetics/synthetic_seq_files/*.fa"].sort.each_with_index do |file, i|
  Resque.enqueue(MfeOfAllStrsFromSeq, {
    sequence: RNA.from_fasta(file).seq,
    output: "/Users/evansenter/Data/MFPT Kinetics/all_structures_per_synthetic_seq/structures_for_seq_%03d.txt" % i
  })
end