require "mysql2"
require "active_record"

class Distribution < ActiveRecord::Base
  validates_presence_of :description, :data_from
  
  has_many :points, dependent: :destroy
  
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
  
  def distribution
    points.map(&:p)
  end
end

class Point < ActiveRecord::Base
  validates_presence_of :k, :p
  
  belongs_to :distribution
  
  default_scope order: "k ASC"
end
