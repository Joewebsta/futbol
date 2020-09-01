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

  def team_ids
    game_teams_data.map { |game| game[:team_id] }.sort_by(&:to_i).uniq
  end

  def filter_by_season(season)
    game_data.select { |game| game[:season] == season }
  end

  def tot_wins_by_team_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:home_team_id]] += 1 if game[:home_goals] > game[:away_goals]
    end
  end

  def tot_games_by_team_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:home_team_id]] += 1
    end
  end

  def win_percent_by_team_season(season)
    tot_wins = tot_wins_by_team_season(season)
    tot_games = tot_games_by_team_season(season)

    team_ids.each_with_object({}) do |team_id, hash|
      win_percent = (tot_wins[team_id] / tot_games[team_id].to_f).round(2)
      hash[team_id] = win_percent unless win_percent.nan?
    end
  end

  def winningest_coach(season)
    winningest_team_id = win_percent_by_team_season(season).max_by { |_id, win_percent| win_percent }[0]
    game_teams_data.find { |game| game[:team_id] == winningest_team_id }[:head_coach]
  end

  def worst_coach(season)
    worst_team_id = win_percent_by_team_season(season).min_by { |_id, win_percent| win_percent }[0]
    game_teams_data.find { |game| game[:team_id] == worst_team_id }[:head_coach]
  end

  def matches_season?(game, season)
    game[:game_id][0..3] == season[0..3]
  end

  def tot_shots_by_team_season(season)
    game_teams_data.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += game[:shots].to_i if matches_season?(game, season)
    end
  end

  def tot_goals_by_team_season(season)
    game_teams_data.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += game[:goals].to_i if matches_season?(game, season)
    end
  end

  def accuracy_by_team_season(season)
    tot_goals = tot_goals_by_team_season(season)
    tot_shots = tot_shots_by_team_season(season)

    team_ids.each_with_object({}) do |id, hash|
      accuracy_percent = (tot_goals[id] / tot_shots[id].to_f).round(3)
      hash[id] = accuracy_percent unless accuracy_percent.nan?
    end
  end

  def most_accurate_team(season)
    most_accurate_team = accuracy_by_team_season(season).max_by { |id_accuracy_arr| id_accuracy_arr[1] }[0]
    team_name_by_id[most_accurate_team]
  end

  def least_accurate_team(season)
    least_accurate_team = accuracy_by_team_season(season).min_by { |id_accuracy_arr| id_accuracy_arr[1] }[0]
    team_name_by_id[least_accurate_team]
  end

  def tackles_by_team_season(season)
    game_teams_data.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:team_id]] += game[:tackles].to_i if matches_season?(game, season)
    end
  end

  def most_tackles(season)
    most_tackles_team_id = tackles_by_team_season(season).max_by { |id_tackles_arr| id_tackles_arr[1] }[0]
    team_name_by_id[most_tackles_team_id]
  end

  def fewest_tackles(season)
    fewest_tackles_team_id = tackles_by_team_season(season).min_by { |id_tackles_arr| id_tackles_arr[1] }[0]
    team_name_by_id[fewest_tackles_team_id]
  end

  def team_info(id)
    team_data = team_data.find { |team| team[:team_id] == id.to_s }
    {
      team_id: team_data[:team_id],
      franchise_id: team_data[:franchiseid],
      team_name: team_data[:teamname],
      abbreviation: team_data[:abbreviation],
      link: team_data[:link]
    }
  end

  def seasons
    game_data.map { |game| game[:season] }.sort_by(&:to_i).uniq
  end

  def games_by_team_id(id)
    game_teams_data.find_all { |team| team[:team_id] == id.to_s }
  end

  def format_season(game)
    start_year = game[:game_id][0..3]
    end_year = start_year.next
    start_year + end_year
  end

  def tot_team_games_by_season(id)
    games = games_by_team_id(id)
    games.each_with_object({}) do |game, hash|
      hash.default = 0
      season = format_season(game)
      hash[season] += 1
    end
  end

  def tot_team_wins_by_season(id)
    games = games = games_by_team_id(id)
    games.each_with_object({}) do |game, hash|
      hash.default = 0
      season = format_season(game)
      hash[season] += 1 if game[:result] == 'WIN'
    end
  end

  def best_season(id)
    games = games_by_team_id(id)
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
# p "Avg goals by season: #{stat_tracker.average_goals_by_season}"
# puts '_______________________________'
# pp "Best offense: #{stat_tracker.best_offense}"
# pp "Worst offense: #{stat_tracker.worst_offense}"
# pp "Highest scoring visitor: #{stat_tracker.highest_scoring_visitor}"
# pp "Lowest scoring visitor: #{stat_tracker.lowest_scoring_visitor}"
# pp "Highest scoring home team: #{stat_tracker.highest_scoring_home_team}"
# pp "Lowest scoring home team: #{stat_tracker.lowest_scoring_home_team}"
# puts '_______________________________'
# pp "Winningest coach: #{stat_tracker.winningest_coach('20122013')}"
# pp "Worst coach: #{stat_tracker.worst_coach('20122013')}"
# pp "Most accurate team: #{stat_tracker.most_accurate_team('20122013')}"
# pp "Least accurate team: #{stat_tracker.least_accurate_team('20122013')}"
# pp "Most tackles: #{stat_tracker.most_tackles('20122013')}"
# pp "Fewest tackles: #{stat_tracker.fewest_tackles('20122013')}"
# puts '_______________________________'
# pp stat_tracker.team_info(27)
# pp stat_tracker.best_season(27)
pp stat_tracker.tot_team_games_by_season(23)
pp stat_tracker.tot_team_wins_by_season(23)
