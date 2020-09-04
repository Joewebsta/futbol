require './lib/collection'
require './lib/game_teams'

class GameTeamsCollection < Collection
  attr_reader :statistics

  def initialize
    super
    @statistics = GameTeams
  end
end
