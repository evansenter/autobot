require "rbfam"
require "awesome_print"
require "resque"
require "./../jobs/fftbor_jobs.rb"

get_seq   = ->(start, stop) { Rbfam::Utils.simple_rna_sequence("NC_000964", start, stop) }
sequences = [
  get_seq[626239, 625839],
  get_seq[625768, 626168],
  get_seq[693610, 694010],
  get_seq[697553, 697953],
  get_seq[2319622, 2319222],
  get_seq[4004369, 4004769]
]

sequences.each_with_index do |sequence, i|
  {
    on:  "..................(((...(((((((.......)))))))........((((((.......))))))..)))((((((((((((.(((((........)))))..............))))))))))))...........................",
    off: ".............((((((((...(((((((.......)))))))........((((((.......))))))..))))))))........(((((........)))))............((((((((((((((.......))))))))))))))......"
  }.each do |state, structure|
    (0..(sequence.length - structure.length)).each do |window_start|
      Resque.enqueue(FftborDistributionFromSequenceAndStructureJob, {
        sequence:    sequence[window_start, structure.length], 
        structure:   structure, 
        description: "Candidate From Template (candidate #{i} window #{window_start} gene #{state})", 
        data_from:   "hmmer candidates"
      })
    end
  end
end