$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/jobs/kinetics_jobs"

ViennaRna.debug = false

Dir["/Users/evansenter/Data/Kinetics/data_for_all_structures_transition_matricies/structures/*"].each do |input|
  %w|hastings no_hastings|.each do |move_klass|
    output_dir = case move_klass
    when "hastings" then "/Users/evansenter/Data/Kinetics/data_for_all_structures_transition_matricies/transition_matrices/transition_rate_matrix_with_hastings"
    when "no_hastings" then "/Users/evansenter/Data/Kinetics/data_for_all_structures_transition_matricies/transition_matrices/transition_rate_matrix_without_hastings"
    end

    Resque.enqueue(TransitionRateMatrixForEquilibrium, {
      structures_file: input,
      matrix_type:     "rate",
      move_klass:      move_klass,
      output_dir:      output_dir
    })
  end
end
