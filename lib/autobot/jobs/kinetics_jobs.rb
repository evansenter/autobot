$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "resque"
require "mysql2"
require "active_record"
require "awesome_print"
require "vienna_rna"

def autobot_helper(filename)
  require "autobot/helpers/%s" % filename
end

module MfeOfAllStrsFromSeq
  @queue = :kinetics

  def self.perform(params)
    ViennaRna.debug = false
    
    File.open(params["output"], ?w) do |output|
      output.write(RNA.from_fasta(params["sequence"]).run(:subopt, e: 1e6).structures.map { |rna| [rna.str, rna.run(:eval, d: 0).mfe].join(?\t) }.join(?\n))
    end
  end
end

module EnergyGridFromStructureFile
  @queue = :kinetics
  
  def self.perform(params)
    sequence   = RNA.from_fasta(params["seq_file"])
    structures = File.read(params["str_file"]).split(?\n).map { |line| line.split(?\t) }
    
    energy_grid = structures.map do |structure, mfe|
      [
        ViennaRna::Global::Rna.bp_distance(sequence.str_1, structure), 
        ViennaRna::Global::Rna.bp_distance(sequence.str_2, structure), 
        Math.exp(-mfe.to_f / ViennaRna::RT)
      ]
    end.sort.group_by { |i, j, boltzmann| [i, j] }.map { |key, values| key << values.map(&:last).inject(&:+) }
  
    energy_grid = energy_grid.map { |i, j, ensemble| [i, j, "%.8f" % (ensemble / energy_grid.map(&:last).inject(&:+))] }
  
    File.open(params["out_file"], ?w) { |file| file.write(energy_grid.map { |row| row.join(?,) }.join(?\n)) }
  end
end