require "mysql2"
require "active_record"
require "rbfam"

class Distribution < ActiveRecord::Base
  validates_presence_of :description, :data_from
  
  has_many :points, dependent: :destroy
  
  before_create do
    dip_test_hash = dip_test
    self.d        = dip_test_hash[:d]
    self.p_value  = dip_test_hash[:p_value]
  end
  
  class DataMigration < ActiveRecord::Migration
    def self.up
      unless ActiveRecord::Base.connection.execute("show tables").find { |i| i == ["distributions"] }
        create_table("distributions") do |table|
          table.text :description
        end
      end
      
      unless ActiveRecord::Base.connection.execute("show tables").find { |i| i == ["points"] }
        create_table("points") do |table|
          table.integer    :k
          table.float      :p
          table.belongs_to :distribution
        end
      end
    end
  end
  
  def self.connect
    ActiveRecord::Base.establish_connection(config = { adapter: "mysql2", username: "root", reconnect: true })

    unless ActiveRecord::Base.connection.execute("show databases").map { |i| i }.flatten.include?("fftbor_data")
      ActiveRecord::Base.connection.create_database("fftbor_data")
    end

    ActiveRecord::Base.establish_connection(config.merge(database: "fftbor_data"))
  end
  
  def self.from_run!(run, description, data_from, options = {})
    Distribution.create({
      sequence:        run.data.seq,
      structure:       run.data.safe_structure,
      sequence_length: run.data.seq.length,
      description:     description, 
      data_from:       data_from,
      points:          run.k_p_points.map { |k, p| Point.new(k: k, p: p) }
    }.merge(options))
  end
  
  def distribution
    points.map(&:p)
  end
  
  def family_name
    case family
    when Rbfam::Family.purine.family_name then "purine"
    when Rbfam::Family.tpp.family_name    then "tpp"
    else family
    end
  end
  
  def dip_test
    command        = %q|Rscript -e "library('diptest'); dip_results <- dip.test(c(%s)); print(dip_results[1]); print(dip_results[2])"| % distribution.join(", ")
    dip_results    = %x|#{command}|    
    
    ->(d, p) { { d: d, p_value: p } }[*dip_results.chomp.split(/\n\n/).map { |line| line.split(/\n/).last.strip.gsub(/(\[1\])\s+/, "").to_f }]
  end
end

class Point < ActiveRecord::Base
  validates_presence_of :k, :p
  
  belongs_to :distribution
  
  default_scope order: "k ASC"
end
