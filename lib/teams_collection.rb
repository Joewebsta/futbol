require './lib/collection'
require './lib/teams'

class TeamsCollection < Collection
  attr_reader :statistics

  def initialize
    super
    @statistics = Teams
  end
end
