class GamesCollection
  attr_reader :games

  def initialize(location)
    @games = CSV.read(location, headers: true, header_converters: :symbol)
    # require 'pry'; binding.pry
  end
end
