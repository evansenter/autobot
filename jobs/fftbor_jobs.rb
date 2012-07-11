require "resque"
require "mysql2"
require "active_record"
require "awesome_print"
require "vienna_rna"
require "rbfam"

module BenchmarkJob
  @queue = :benchmarking

  def self.perform(params)
    Run.connect
    
    size = params["sequence"].length
    
    ["." * size, ViennaRna::Fold.run(params["sequence"]).structure].each do |structure|
      results = case params["algorithm"]
      when "rnabor" then ViennaRna::Rnabor.new(sequence: params["sequence"], structure: structure).run
      when "fftbor" then ViennaRna::Fftbor.new(sequence: params["sequence"], structure: structure).run
      end
      
      Run.create({
        sequence:        params["sequence"], 
        structure:       structure, 
        sequence_length: size, 
        algorithm:       params["algorithm"], 
        time:            results.runtime.real
      })
    end
  end
end

module DuplicateJob
  @queue = :benchmarking

  def self.perform(params)
    Run.connect
    
    run = Run.find(params["id"])
    
    results = case run.algorithm
    when "rnabor" then ViennaRna::Rnabor.new(sequence: run.sequence, structure: run.structure).run
    when "fftbor" then ViennaRna::Fftbor.new(sequence: run.sequence, structure: run.structure).run
    end
      
    Run.create({
      sequence:        run.sequence, 
      structure:       run.structure, 
      sequence_length: run.sequence.length, 
      algorithm:       run.algorithm, 
      time:            results.runtime.real
    })
  end
end

module FftborToFileJob
  @queue = :fftbor
  
  def self.connect
    Rbfam.script("sequences_in_mysql")
  end

  def self.perform(params)
    connect
    
    rbfam   = SequenceTable.find(params["id"]).to_rbfam_sequence
    results = ViennaRna::Fftbor.run(seq: rbfam.seq, str: :mfe).response
    
    File.open(File.join(params["path"], "#{params['id']}.out"), "w") do |file|
      file.write(results)
    end
  end
end