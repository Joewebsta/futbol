require 'csv'

class StatTracker
  def self.from_csv(locations)
    raw_data = {}
    raw_data[:game_data] = CSV.read(locations[:games], headers: true, header_converters: :symbol)
    raw_data[:team_data] = CSV.read(locations[:teams], headers: true, header_converters: :symbol)
    raw_data[:game_teams_data] = CSV.read(locations[:game_teams], headers: true, header_converters: :symbol)
    StatTracker.new(raw_data)
  end

  attr_reader :game_data, :team_data, :game_teams_data

  def initialize(raw_data)
    @game_data = raw_data[:game_data]
    @team_data = raw_data[:team_data]
    @game_teams_data = raw_data[:game_teams_data]
  end

  def highest_total_score
    game_data.map { |game| game[:away_goals].to_i + game[:home_goals].to_i }.max
  end

  def lowest_total_score
    game_data.map { |game| game[:away_goals].to_i + game[:home_goals].to_i }.min
  end

  def percentage_home_wins
    tot_games = game_data.count
    home_wins = game_data.select { |game| game[:home_goals] > game[:away_goals] }.count.to_f
    (home_wins / tot_games * 100).round(2)
  end

  def percentage_visitor_wins
    tot_games = game_data.count
    visitor_wins = game_data.select { |game| game[:away_goals] > game[:home_goals] }.count.to_f
    (visitor_wins / tot_games * 100).round(2)
  end

  def percentage_ties
    100.00 - percentage_home_wins - percentage_visitor_wins
  end

  def count_of_games_by_season
    game_data.sort_by { |game| game[:season] }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:season]] += 1
    end
  end

  def count_of_goals_by_season
    game_data.sort_by { |row| row[:season] }.each_with_object({}) do |row, hash|
      hash.default = 0
      hash[row[:season]] += (row[:away_goals].to_i + row[:home_goals].to_i)
    end
  end

  def average_goals_per_game
    tot_games = game_data.count
    tot_goals = game_data.reduce(0) do |goal_count, game|
      goal_count + game[:away_goals].to_f + game[:home_goals].to_f
    end

    (tot_goals / tot_games).round(2)
  end

  def average_goals_by_season
    tot_goals = count_of_goals_by_season
    tot_games = count_of_games_by_season

    tot_goals.each_with_object({}) do |season_goals_arr, hash|
      season = season_goals_arr[0]
      hash[season] = (tot_goals[season].to_f / tot_games[season]).round(2)
    end
  end

  def count_of_teams
    team_data.by_col[0].count
  end

  def tot_goals_by_team(data)
    data.sort_by { |game| game[:team_id].to_i }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += game[:goals].to_i
    end
  end

  def tot_games_by_team(data)
    data.sort_by { |game| game[:team_id].to_i }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += 1
    end
  end

  def avg_goals_per_game_by_team(data)
    tot_goals_by_team(data).each_with_object({}) do |team_id_goals, hash|
      team_id = team_id_goals[0]
      team_goals = team_id_goals[1].to_f
      tot_team_games = tot_games_by_team(data)[team_id]

      hash[team_id] = (team_goals / tot_team_games).round(2)
    end
  end

  def team_name_by_id
    team_data.sort_by { |row| row[:team_id].to_i }.each_with_object({}) do |row, hash|
      hash[row[:team_id]] = row[:teamname]
    end
  end

  def best_offense
    best_offense_arr = avg_goals_per_game_by_team(game_teams_data).max_by { |_id, goals| goals }
    best_offense_id = best_offense_arr[0]
    team_name_by_id[best_offense_id]
  end

  def worst_offense
    worst_offense_arr = avg_goals_per_game_by_team(game_teams_data).min_by { |_id, goals| goals }
    worst_offense_id = worst_offense_arr[0]
    team_name_by_id[worst_offense_id]
  end

  def filter_by_hoa(type)
    game_teams_data.select { |game| game[:hoa] == type }
  end

  def highest_scoring_visitor
    away_games_arr = filter_by_hoa('away')
    highest_scoring_visitor_by_id = avg_goals_per_game_by_team(away_games_arr).max_by { |_id, goals| goals }[0]
    team_name_by_id[highest_scoring_visitor_by_id]
  end

  def lowest_scoring_visitor
    away_games_arr = filter_by_hoa('away')
    lowest_scoring_visitor_by_id = avg_goals_per_game_by_team(away_games_arr).min_by { |_id, goals| goals }[0]
    team_name_by_id[lowest_scoring_visitor_by_id]
  end

  def highest_scoring_home_team
    home_games = filter_by_hoa('home')
    high_scoring_home_team_id = avg_goals_per_game_by_team(home_games).max_by { |_id, goals| goals }[0]
    team_name_by_id[high_scoring_home_team_id]
  end

  def lowest_scoring_home_team
    home_games = filter_by_hoa('home')
    low_scoring_home_team_id = avg_goals_per_game_by_team(home_games).min_by { |_id, goals| goals }[0]
    team_name_by_id[low_scoring_home_team_id]
  end

  def tot_wins_loses_by_team(type)
    game_teams_data.sort_by { |game| game[:team_id].to_i }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += 1 if game[:result] == type
    end
  end

  def win_percent_by_team
    tot_wins = tot_wins_loses_by_team('WIN')
    tot_games = tot_games_by_team(game_teams_data)

    tot_wins.each_with_object({}) do |team_id_wins_arr, hash|
      team_id = team_id_wins_arr[0]
      hash[team_id] = (tot_wins[team_id] / tot_games[team_id].to_f).round(2)
    end
  end

  def winningest_coach
    winningest_team_id = win_percent_by_team.max_by { |_id, win_percent| win_percent }[0]
    game_teams_data.find { |game| game[:team_id] == winningest_team_id }[:head_coach]
  end

  def worst_coach
    worst_team_id = win_percent_by_team.min_by { |_id, win_percent| win_percent }[0]
    game_teams_data.find { |game| game[:team_id] == worst_team_id }[:head_coach]
  end
  # Can I refactor any methods above to use find?
end

game_path = './data/games.csv'
team_path = './data/teams.csv'
game_teams_path = './data/game_teams.csv'

locations = {
  games: game_path,
  teams: team_path,
  game_teams: game_teams_path
}

stat_tracker = StatTracker.from_csv(locations)
# pp "Highest total score: #{stat_tracker.highest_total_score}"
# pp "Lowest total score: #{stat_tracker.lowest_total_score}"
# pp "Percentage home wins: #{stat_tracker.percentage_home_wins}"
# pp "Percentage visitor wins: #{stat_tracker.percentage_visitor_wins}"
# pp "Percentage ties: #{stat_tracker.percentage_ties}"
# pp "Count of games by season: #{stat_tracker.count_of_games_by_season}"
# pp "Avg goals per game: #{stat_tracker.average_goals_per_game}"
# p "Avg goals by season: #{stat_tracker.average_goals_by_season}"
# puts '_______________________________'
# pp "Best offense: #{stat_tracker.best_offense}"
# pp "Worst offense: #{stat_tracker.worst_offense}"
# pp "Highest scoring visitor: #{stat_tracker.highest_scoring_visitor}"
# pp "Lowest scoring visitor: #{stat_tracker.lowest_scoring_visitor}"
# pp "Highest scoring home team: #{stat_tracker.highest_scoring_home_team}"
# pp "Lowest scoring home team: #{stat_tracker.lowest_scoring_home_team}"
# puts '_______________________________'
# pp "Winningest coach: #{stat_tracker.winningest_coach}"
pp "Worst coach: #{stat_tracker.worst_coach}"
