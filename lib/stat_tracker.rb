require 'csv'
require './lib/games_collection'
require './lib/game_statistics'
require './lib/league_statistics'
require './lib/season_statistics'
require './lib/team_statistics'

class StatTracker
  include GameStatistics
  include LeagueStatistics
  include SeasonStatistics
  include TeamStatistics

  attr_reader :games, :team_data, :game_teams_data

  def initialize(data)
    @games = data[:games]
    @team_data = data[:teams]
    @game_teams_data = data[:game_teams]
  end

  def self.from_csv(locations)
    data = {}
    data[:games] = GamesCollection.from_csv(locations[:games])
    data[:teams] = CSV.read(locations[:teams], headers: true, header_converters: :symbol)
    data[:game_teams] = CSV.read(locations[:game_teams], headers: true, header_converters: :symbol)
    StatTracker.new(data)
  end
end
