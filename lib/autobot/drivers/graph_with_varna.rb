$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/jobs/visualization_jobs"

rna_by_species  = Dir["/Users/evansenter/Data/Ribofinder/putative_bacterial_rnas/*"].inject({}) { |hash, directory| hash.merge(directory => RNA.load_all(directory).inject([]) { |array, rna| array + %i|str_1 str_2|.map { |structure| rna.one_str(structure).tap { |rna| rna.comment = rna.comment.gsub(/[^A-Z0-9]/, ?_) + "_#{structure}" } } } ) }

rna_by_species.map do |folder, switches|
  switches.each_slice(2).map do |riboswitch|
    folder_name = File.join(folder, riboswitch.first.name.gsub(/_str_.*$/, ""))
    FileUtils.mkdir(folder_name) rescue nil
    riboswitch.map do |rna| 
      # ap({
      Resque.enqueue(Varna, {
        seq:    rna.seq,
        str:    rna.str,
        name:   rna.name,
        output: File.join(folder_name, "%s.png" % rna.name)
      })
    end
  end
end
