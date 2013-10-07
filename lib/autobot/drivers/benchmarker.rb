$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "vienna_rna"
require "awesome_print"
require "resque"
require "autobot/helpers/benchmark_mysql_config"
require "autobot/jobs/fftx_jobs"

ViennaRna.debug = false

# [20, 40, 60, 80, 100, 120, 140, 160, 200, 250, 300].inject({}) do |hash, size| 
#   hash.merge(size => (case size; when 1..160 then 100; else 3; end))
# end.each do |size, iterations|
#   iterations.times do |i|
#     sequence = size.times.inject("") { |string, _| string + %w[A U C G][rand(4)] }
#     
#     Resque.enqueue(BenchmarkJob, { algorithm: :rnabor, sequence: sequence })
#     Resque.enqueue(BenchmarkJob, { algorithm: :fftbor, sequence: sequence })
#   end
# end

# Run.find_in_batches do |runs|
#   runs.each do |run|
#     Resque.enqueue(DuplicateJob, { id: run.id })
#     Resque.enqueue(DuplicateJob, { id: run.id })
#   end
# end