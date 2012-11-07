require "resque"
require "mysql2"
require "active_record"
require "awesome_print"
require "vienna_rna"
require "rbfam"
require "diverge"

def autobot_helper(filename)
  require "./helpers/%s.rb" % filename
end

module BenchmarkJob
  @queue = :benchmarking

  def self.perform(params)
    autobot_helper("benchmark_mysql_config")
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
    autobot_helper("benchmark_mysql_config")
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

  def self.perform(params)
    Rbfam.script("sequences_in_mysql")
    
    rbfam   = SequenceTable.find(params["id"]).to_rbfam_sequence
    results = ViennaRna::Fftbor.run(seq: rbfam.seq, str: :mfe).response
    
    File.open(File.join(params["path"], "#{params['id']}.out"), "w") do |file|
      file.write(results)
    end
  end
end

module DivergenceJob
  @queue = :divergence
  
  def self.perform(params)
    autobot_helper("divergence_mysql_config")
    Run.connect
    
    rnabor = ViennaRna::Rnabor.run(sequence: params["sequence"], structure: params["structure"])
    fftbor = ViennaRna::Fftbor.run(sequence: params["sequence"], structure: params["structure"])
    
    rnabor_distribution = rnabor.distribution
    fftbor_distribution = fftbor.distribution + ([0] * (rnabor_distribution.length - fftbor.distribution.length))
    
    Run.create({
      sequence:        params["sequence"], 
      sequence_length: params["sequence"].length, 
      structure:       params["structure"], 
      algorithm:       "RNAbor vs. FFTbor with max base pair distance (Z_k/Z)", 
      tvd:             Diverge.new(rnabor_distribution, fftbor_distribution).tvd,
      count:           -1,
      fftbor_time:     fftbor.runtime.real,
      rnabor_time:     rnabor.runtime.real
    })
  end
end

module DataLoaderJob
  @queue = :fftbor
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
    
    log        = File.read(params["log_path"])
    sequence   = log.split(/\n/).first.split(/\s+/)[1]
    structure  = log.split(/\n/).first.split(/\s+/)[2]
    parsed_log = log.split(/\n/).select { |line| line =~ /^\d+\t\d(\.\d+)?$/ }.map { |line| ->(k, p) { { k: k, p: p } }[*line.split(/\t/)] }

    Distribution.create({
      sequence:        sequence,
      structure:       structure,
      sequence_length: sequence.length,
      output:          log,
      description:     File.basename(params["log_path"], ".log"), 
      data_from:       params["data_from"],
      points:          parsed_log.map(&Point.method(:new))
    })
  end
end

module DipTestJob
  @queue = :fftbor
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
    
    data = Distribution.find(params["id"])
    data.update_attributes(data.dip_test)
  end
end

module FftborDistributionFromMfeJob
  @queue = :fftbor
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
    
    fold = ViennaRna::Fold.run(seq: params["sequence"])
    run  = ViennaRna::Fftbor.run({ seq: params["sequence"], str: fold.structure }, params["fftbor"] || {})
    
    Distribution.from_run!(run, params["description"], params["data_from"], (params["options"] || {}).merge(mfe: fold.mfe))
  end
end

module FftborDistributionFromEmptyJob
  @queue = :fftbor
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
        
    Distribution.from_run!(ViennaRna::Fftbor.run(params["sequence"]), params["description"], params["data_from"], (params["options"] || {}).merge(mfe: 0))
  end
end

module FftxDistributionFromSequenceAndStructureJob
  @queue = :fftx
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
        
    fftx = Kernel.const_get("ViennaRna::%s" % params["algorithm"].demodulize)
        
    Distribution.from_run!(
      fftx.run({ seq: params["sequence"], str: params["structure"] }, params["fftx"] || {}), 
      params["description"], 
      params["data_from"],
      params["options"] || {}
    )
  end
end

module AddMfeToDistributionJob
  @queue = :fftbor
  
  def self.perform(params)
    autobot_helper("data_loader_mysql_config")
    
    distribution = Distribution.find(params["id"])
    distribution.update_attribute(:mfe, ViennaRna::Eval.run(seq: distribution.sequence, str: distribution.structure).mfe)
  end
end