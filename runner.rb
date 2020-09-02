require './lib/stat_tracker'

locations = {
  games: './data/games.csv',
  teams: './data/teams.csv',
  game_teams: './data/game_teams.csv'
}

stat_tracker = StatTracker.from_csv(locations)
