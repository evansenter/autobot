$: << "/Users/evansenter/Source/autobot/lib" unless $:.include?("/Users/evansenter/Source/autobot/lib")
require "resque"
require "awesome_print"
require "wrnap"

def autobot_helper(filename)
  require "autobot/helpers/%s" % filename
end

module Varna
  @queue = :visualization

  def self.perform(params)
    RNA(params["seq"], params["str"], nil, params["name"]).run_varna(o: params["output"])
  end
end
