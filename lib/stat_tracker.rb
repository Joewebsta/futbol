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
    game_data.map { |row| row[:away_goals].to_i + row[:home_goals].to_i }.max
  end

  def lowest_total_score
    game_data.map { |row| row[:away_goals].to_i + row[:home_goals].to_i }.min
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
    game_data.sort_by { |row| row[:season] }.each_with_object({}) do |row, hash|
      hash[row[:season]] ? hash[row[:season]] += 1 : hash[row[:season]] = 1
    end
  end

  def count_of_goals_by_season
    game_data.sort_by { |row| row[:season] }.each_with_object({}) do |row, hash|
      if hash[row[:season]]
        hash[row[:season]] += row[:away_goals].to_i + row[:home_goals].to_i
      else
        hash[row[:season]] = row[:away_goals].to_i + row[:home_goals].to_i
      end
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

    tot_goals.each_with_object({}) do |year, hash|
      hash[year[0]] = (tot_goals[year[0]].to_f / tot_games[year[0]]).round(2)
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
# pp "Avg goals by season: #{stat_tracker.average_goals_by_season}"
# puts '_______________________________'
# pp "Best offense: #{stat_tracker.best_offense}"
# pp "Worst offense: #{stat_tracker.worst_offense}"
# pp "Highest scoring visitor: #{stat_tracker.highest_scoring_visitor}"
# pp "Lowest scoring visitor: #{stat_tracker.lowest_scoring_visitor}"
