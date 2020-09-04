require 'csv'

class Collection
  attr_reader :collection

  def initialize
    @collection = []
  end

  def self.from_csv(csv_location)
    new_games_collection = new
    new_games_collection.convert_csv(csv_location)
    new_games_collection.collection
  end

  def convert_csv(csv_location)
    CSV.foreach(csv_location, headers: true, header_converters: :symbol) do |row|
      convert_row(row)
    end
  end

  def convert_row(row)
    collection << statistics.new(row)
  end
end
