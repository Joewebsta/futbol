require 'csv'
require './lib/game_teams'

class GameTeamsCollection
  attr_reader :games_teams, :collection

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
    games.each { |row| collection << GameTeams.new(row) }
  end
end
