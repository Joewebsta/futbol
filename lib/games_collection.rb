require './lib/collection'
require './lib/games'

class GamesCollection < Collection
  attr_reader :statistics

  def initialize
    super
    @statistics = Games
  end
end
