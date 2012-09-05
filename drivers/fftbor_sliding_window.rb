require "vienna_rna"
require "awesome_print"
require "resque"
require "./../jobs/fftbor_jobs.rb"

if (3..4) === ARGV.length
  sequence_dir, structure, data_from, details = ARGV[0, 4]
  
  Dir[File.join(sequence_dir, "*.fa")].each do |path|
    fasta = Bio::FlatFile.open(path).first
    
    (0..(fasta.seq.length - structure.length)).each do |window_start|
      Resque.enqueue(FftborDistributionFromSequenceAndStructureJob, {
        sequence:    fasta.seq[window_start, structure.length], 
        structure:   structure, 
        description: fasta.definition.gsub(/\W+/, "_"), 
        data_from:   data_from,
        window:      window_start,
        details:     details
      })
    end
  end
else
  puts "ruby ./fftbor_sliding_window.rb SEQUENCE_DIR STRUCTURE DATA_FROM DETAILS"
end