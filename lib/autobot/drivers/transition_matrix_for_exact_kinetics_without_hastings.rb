$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "vienna_rna"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

Dir["/Users/evansenter/Data/MFPT Kinetics/all_structures_per_synthetic_seq/*.txt"].each do |input|
  Resque.enqueue(TransitionMatrixForExactKineticsWithoutHastings, { input: input })
end