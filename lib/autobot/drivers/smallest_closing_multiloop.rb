$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

Dir["/Users/evansenter/Data/Ribofinder/candidate_riboswitches_with_poly_u_tail/unafold_full_sequences_with_gene_on_constraints/**/*spliced*.fa"].map do |file|
  Resque.enqueue(ClosingMultiloop, {
    input: file,
    output: File.join(File.dirname(file), "multiloop_indices_for_%s.txt" % File.basename(file, ".fa"))
  })
end
