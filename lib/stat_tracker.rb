require 'csv'
require './lib/games_collection'
require './lib/teams_collection'
require './lib/game_teams_collection'

require './lib/game_statistics'
require './lib/league_statistics'
require './lib/season_statistics'
require './lib/team_statistics'

class StatTracker
  include GameStatistics
  include LeagueStatistics
  include SeasonStatistics
  include TeamStatistics

  attr_reader :games, :teams, :game_teams

  def self.from_csv(locations)
    data = {}
    data[:games] = GamesCollection.from_csv(locations[:games])
    data[:teams] = TeamsCollection.from_csv(locations[:teams])
    data[:game_teams] = GameTeamsCollection.from_csv(locations[:game_teams])
    StatTracker.new(data)
  end

  def initialize(data)
    @games = data[:games]
    @teams = data[:teams]
    @game_teams = data[:game_teams]
  end
end
