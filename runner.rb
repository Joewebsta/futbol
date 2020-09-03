require './lib/stat_tracker'

locations = {
  games: './data/games.csv',
  teams: './data/teams.csv',
  game_teams: './data/game_teams.csv'
}

stat_tracker = StatTracker.from_csv(locations)

pp "Highest total score: #{stat_tracker.highest_total_score}"
pp "Lowest total score: #{stat_tracker.lowest_total_score}"
pp "Percentage home wins: #{stat_tracker.percentage_home_wins}"
pp "Percentage visitor wins: #{stat_tracker.percentage_visitor_wins}"
pp "Percentage ties: #{stat_tracker.percentage_ties}"
pp "Count of games by season: #{stat_tracker.count_of_games_by_season}"
pp "Avg goals per game: #{stat_tracker.average_goals_per_game}"
p "Avg goals by season: #{stat_tracker.average_goals_by_season}"
puts '_______________________________'
pp "Best offense: #{stat_tracker.best_offense}"
pp "Worst offense: #{stat_tracker.worst_offense}"
pp "Highest scoring visitor: #{stat_tracker.highest_scoring_visitor}"
pp "Lowest scoring visitor: #{stat_tracker.lowest_scoring_visitor}"
pp "Highest scoring home team: #{stat_tracker.highest_scoring_home_team}"
pp "Lowest scoring home team: #{stat_tracker.lowest_scoring_home_team}"
puts '_______________________________'
pp "Winningest coach: #{stat_tracker.winningest_coach('20132014')}"
pp "Winningest coach: #{stat_tracker.winningest_coach('20142015')}"
pp "Worst coach: #{stat_tracker.worst_coach('20132014')}"
pp "Worst coach: #{stat_tracker.worst_coach('20142015')}"
pp "Most accurate team: #{stat_tracker.most_accurate_team('20132014')}"
pp "Most accurate team: #{stat_tracker.most_accurate_team('20142015')}"
pp "Least accurate team: #{stat_tracker.least_accurate_team('20132014')}"
pp "Least accurate team: #{stat_tracker.least_accurate_team('20142015')}"
pp "Most tackles: #{stat_tracker.most_tackles('20132014')}"
pp "Most tackles: #{stat_tracker.most_tackles('20142015')}"
pp "Fewest tackles: #{stat_tracker.fewest_tackles('20132014')}"
pp "Fewest tackles: #{stat_tracker.fewest_tackles('20142015')}"
puts '_______________________________'
pp stat_tracker.team_info(18)
pp stat_tracker.best_season(6)
pp stat_tracker.worst_season(6)
pp stat_tracker.average_win_percentage(6)
pp stat_tracker.most_goals_scored(18)
pp stat_tracker.fewest_goals_scored(18)
pp stat_tracker.favorite_opponent(18)
pp stat_tracker.rival(18)
