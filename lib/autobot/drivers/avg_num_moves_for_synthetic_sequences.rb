$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

(0...1000).each do |i|
  Resque.enqueue(AverageNumberOfMoves, {
    input:  "/Users/evansenter/Data/Kinetics/all_structures_per_synthetic_seq/structures_for_seq_%03d.txt" % i,
    output: "/Users/evansenter/Data/Kinetics/data_for_all_structures_transition_matricies/avg_num_moves_for_synthetic_seqs/seq_%03d.txt" % i
  })
end
