$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "resque"
require "awesome_print"
require "wrnap"
require "~/Data/Kinetics/data_for_all_structures_transition_matricies/structural_enumeration_to_transition_matrix.rb"

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

module KineticsUsingRScript
  @queue = :kinetics

  def self.perform(params)
    File.open(params["output"], ?w) { |file| file.write(%x|Rscript /Users/evansenter/Source/rna_kinetics/kinetics/matrix_inverse/fftbor2d.r '#{params["input"]}'|) }
  end
end

module TransitionRateMatrixForEquilibrium
  @queue = :kinetics

  def self.perform(params)
    move_klass = case params["move_klass"]
    when "hastings"    then MoveWithHastings
    when "no_hastings" then MoveWithoutHastings
    end

    Converter.to_matrix(params["structures_file"], params["matrix_type"].to_sym, move_klass, params["output_dir"])
  end
end

module AverageNumberOfMoves
  @queue = :kinetics

  def self.perform(params)
    File.open(params["output"], ?w) do |file|
      file.write("%f\n" % Converter.module_eval { avg_neighbors(move_set(parse_structures(params["input"]))) })
    end
  end
end

module ClosingMultiloop
  @queue = :kinetics

  def self.perform(params)
    closing_bp = %x|python ~/Source/smallest_multiloop/multiloop_index.py #{params["input"]}|

    File.open(params["output"], ?w) { |file| file.write(closing_bp) }
  end
end
