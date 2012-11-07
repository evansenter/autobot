require "vienna_rna"
require "awesome_print"
require "resque"
require "./../helpers/divergence_mysql_config.rb"
require "./../jobs/fftx_jobs.rb"

# 20.step(300, 20).each do |size|
#   3.times do
#     sequence = size.times.inject("") { |string, _| string + %w[A U C G][rand(4)] }
#          
#     ["." * sequence.length, ViennaRna::Fold.new(sequence).run.structure].each do |structure|
#       Resque.enqueue(DivergenceJob, { sequence: sequence, structure: structure })
#     end
#   end
# end

# [400, 500].each do |size|
#   Resque.enqueue(DivergenceJob, { sequence: size.times.inject("") { |string, _| string + %w[A U C G][rand(4)] } })
# end

50.times do
  sequence = rand(200).times.inject("") { |string, _| string + %w[A U C G][rand(4)] }
         
  ["." * sequence.length, ViennaRna::Fold.new(sequence).run.structure].each do |structure|
    Resque.enqueue(DivergenceJob, { sequence: sequence, structure: structure })
  end
end
