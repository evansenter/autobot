$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

Dir["/Users/evansenter/Data/MFPT Kinetics/synthetic_seq_files/*.fa"].sort.each_with_index do |file, i|
  Resque.enqueue(KineticsUsingRScript, {
    input:  file,
    output: "/Users/evansenter/Data/MFPT Kinetics/mfpt_output_from_r_code_calling_fftbor2d/mfpt_for_seq_%03d.txt" % i
  })
end