require "mysql2"
require "active_record"

class Run < ActiveRecord::Base
  validates_presence_of :sequence, :sequence_length, :structure, :algorithm, :tvd, :fftbor_time, :rnabor_time
  
  def self.connect
    ActiveRecord::Base.establish_connection(config = { adapter: "mysql2", username: "root", reconnect: true })

    unless ActiveRecord::Base.connection.execute("show databases").map { |i| i }.flatten.include?("fftbor_divergence")
      ActiveRecord::Base.connection.create_database("fftbor_divergence")
    end

    ActiveRecord::Base.establish_connection(config.merge(database: "fftbor_divergence"))
    
    inline_rails if defined?(inline_rails)
  end
end