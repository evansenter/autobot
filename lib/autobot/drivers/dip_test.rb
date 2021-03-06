$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "wrnap"
require "awesome_print"
require "resque"
require "autobot/helpers/data_loader_mysql_config"
require "autobot/jobs/fftx_jobs"

ViennaRna.debug = false
where_clause    = ARGV[0]

if where_clause
  inline_rails if defined?(inline_rails)

  Distribution.where(where_clause).each do |distribution|
    Resque.enqueue(DipTestJob, id: distribution.id)
  end
else
  puts "ruby ./dip_test.rb MYSQL_WHERE_CLAUSE"
end
