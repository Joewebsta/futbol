require './lib/games'

class GamesCollection
  attr_reader :games, :collection

  def initialize
    @collection = []
  end

  def self.from_csv(csv_location)
    new_games_collection = new
    new_games_collection.convert_csv(csv_location)
    new_games_collection.collection
  end

  def convert_csv(csv_location)
    games = CSV.read(csv_location, headers: true, header_converters: :symbol)
    games.each { |row| collection << Games.new(row) }
  end
end
