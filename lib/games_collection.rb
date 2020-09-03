require './lib/games'

class GamesCollection
  attr_reader :games, :collection

  def initialize(location)
    @games = CSV.read(location, headers: true, header_converters: :symbol)
    @collection = []
    load_csv
  end

  def load_csv
    games.each do |row|
      collection << Games.new(row)
    end
  end
end
