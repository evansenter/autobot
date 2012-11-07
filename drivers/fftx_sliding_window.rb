require "vienna_rna"
require "awesome_print"
require "resque"
require "./../jobs/fftx_jobs.rb"

if (4..5) === ARGV.length
  sequence_dir, algorithm, structure, data_from, details = ARGV[0, 5]
  
  Dir[File.join(sequence_dir, "*.fa")].each do |path|
    fasta = Bio::FlatFile.open(path).first
    
    (0..(fasta.seq.length - structure.length)).each do |window_start|
      Resque.enqueue(FftxDistributionFromSequenceAndStructureJob, {
        algorithm:   algorithm, 
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
  puts "ruby ./fftx_sliding_window.rb SEQUENCE_DIR ALGORITHM STRUCTURE DATA_FROM DETAILS"
end