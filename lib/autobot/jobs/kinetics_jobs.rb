$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "resque"
require "awesome_print"
require "vienna_rna"

def autobot_helper(filename)
  require "autobot/helpers/%s" % filename
end

class Structure
  attr_reader :structure, :mfe, :index
  
  def initialize((structure, mfe), index)
    @structure, @mfe, @index = structure, mfe.to_f, index
  end
  
  def distance(other_str)
    ViennaRna::Global::Rna.bp_distance(structure, other_str.structure)
  end
end

class MetropolisMove
  attr_reader :from, :to, :p
  
  def initialize(from, to, p: nil, num_moves: nil)
    @from, @to   = from, to
    @p           = p ? p : probability(num_moves)
  end
  
  def probability(num_moves)
    [1.0, Math.exp(-(to.mfe - from.mfe) / ViennaRna::RT)].min / num_moves
  end
  
  def to_csv
    "%d,%d,%.#{Float::DIG}f" % [from.index, to.index, p]
  end
  
  def to_debug_string
    "from: %s (%+.2f)\tto: %s (%+.2f)\tp: %.#{Float::DIG}f" % [from.structure, from.mfe, to.structure, to.mfe, p]
  end
  
  def <=>(other_move)
    from.index != other_move.from.index ? from.index <=> other_move.from.index : to.index <=> other_move.to.index
  end
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

module TransitionMatrixForExactKineticsWithoutHastings
  @queue = :kinetics
  
  def self.perform(params)
    structures  = File.read(params["input"]).split(?\n).map { |line| line.split(?\t) }.each_with_index.map(&Structure.method(:new))
    empty_index = structures.find { |structure| structure.mfe.zero? }.index
    mfe_index   = structures.min { |a, b| a.mfe <=> b.mfe }.index
    move_set    = structures.inject({}) do |hash, structure_1|
      hash.tap do
        hash[structure_1] = structures.select do |structure_2|
          structure_1.distance(structure_2) == 1
        end
      end
    end

    move_list = move_set.inject([]) do |list, (from, to_array)|
      outgoing  = to_array.map { |to| MetropolisMove.new(from, to, num_moves: to_array.size) }
      all_moves = (outgoing + [MetropolisMove.new(from, from, p: 1 - outgoing.map(&:p).inject(&:+))]).select { |move| move.p > 0 }
      list + all_moves 
    end.sort

    File.open("/Users/evansenter/Data/MFPT Kinetics/structural_energy_grids_for_synthetic_seq_without_hastings_single_bp_moves/%s__%d_%d.csv" % [File.basename(params["input"], ".txt"), empty_index, mfe_index], ?w) do |file|
      file.write(move_list.map(&:to_csv).join(?\n) + ?\n)
    end
  end
end

module KineticsUsingRScript
  @queue = :kinetics
  
  def self.perform(params)
    File.open(params["output"], ?w) { |file| file.write(%x|Rscript /Users/evansenter/Source/rna_kinetics/kinetics/matrix_inverse/fftbor2d.r '#{params["input"]}'|) }
  end
end
