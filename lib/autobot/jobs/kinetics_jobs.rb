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