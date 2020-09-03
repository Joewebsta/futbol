require './lib/teams'

class TeamsCollection
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
    teams = CSV.read(csv_location, headers: true, header_converters: :symbol)
    teams.each { |row| collection << Teams.new(row) }
  end
end
