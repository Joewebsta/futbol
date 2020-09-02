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
    (home_wins / tot_games).round(2)
  end

  def percentage_visitor_wins
    tot_games = game_data.count
    visitor_wins = game_data.select { |game| game[:away_goals] > game[:home_goals] }.count.to_f
    (visitor_wins / tot_games).round(2)
  end

  def percentage_ties
    (1.0 - percentage_home_wins - percentage_visitor_wins).round(2)
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
    game_teams_data.find_all { |game| game[:game_id][0..3] == season[0..3] }
  end

  def tot_wins_by_coach_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:head_coach]] += 1 if game[:result] == 'WIN'
    end
  end

  def tot_games_by_coach_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:head_coach]] += 1
    end
  end

  def win_percent_by_coach_season(season)
    tot_wins = tot_wins_by_coach_season(season)
    tot_games = tot_games_by_coach_season(season)

    tot_games.each_with_object({}) do |coach_games_arr, hash|
      coach = coach_games_arr[0]
      win_percent = (tot_wins[coach] / tot_games[coach].to_f).round(3)
      hash[coach] = win_percent unless win_percent.nan?
    end
  end

  def winningest_coach(season)
    win_percent_by_coach_season(season).max_by { |_name, win_percent| win_percent }[0]
  end

  def worst_coach(season)
    win_percent_by_coach_season(season).min_by { |_name, win_percent| win_percent }[0]
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
    team_information = team_data.find { |team| team[:team_id] == id.to_s }
    {
      team_id: team_information[:team_id],
      franchise_id: team_information[:franchiseid],
      team_name: team_information[:teamname],
      abbreviation: team_information[:abbreviation],
      link: team_information[:link]
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
    games = games_by_team_id(id)
    games.each_with_object({}) do |game, hash|
      hash.default = 0
      season = format_season(game)
      hash[season] += 1 if game[:result] == 'WIN'
    end
  end

  def team_win_percentage_by_season(id)
    tot_wins = tot_team_wins_by_season(id)
    tot_games = tot_team_games_by_season(id)

    seasons.each_with_object({}) do |season, hash|
      hash[season] = (tot_wins[season] / tot_games[season].to_f).round(2)
    end
  end

  def best_season(id)
    team_win_percentage_by_season(id).max_by { |team_win_percent_arr| team_win_percent_arr[1] }[0]
  end

  def worst_season(id)
    team_win_percentage_by_season(id).min_by { |team_win_percent_arr| team_win_percent_arr[1] }[0]
  end

  def average_win_percentage(id)
    tot_wins = tot_team_wins_by_season(id).values.sum
    tot_games = tot_team_games_by_season(id).values.sum.to_f
    (tot_wins / tot_games).round(2)
  end

  def most_goals_scored(id)
    games = games_by_team_id(id)
    games.max_by { |game| game[:goals] }[:goals].to_i
  end

  def fewest_goals_scored(id)
    games = games_by_team_id(id)
    games.min_by { |game| game[:goals] }[:goals].to_i
  end

  def home_and_away_games(id)
    game_data.find_all { |game| game[:home_team_id] == id.to_s || game[:away_team_id] == id.to_s }
  end

  def wins_vs_opponents(id)
    home_and_away_games(id).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:away_team_id]] += 1 if (game[:home_goals] < game[:away_goals]) && game[:away_team_id] != id.to_s
      hash[game[:home_team_id]] += 1 if (game[:away_goals] < game[:home_goals]) && game[:home_team_id] != id.to_s
    end
  end

  def tot_games_vs_opponents(id)
    home_and_away_games(id).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game[:away_team_id]] += 1 unless game[:away_team_id] == id.to_s
      hash[game[:home_team_id]] += 1 unless game[:home_team_id] == id.to_s
    end
  end

  def win_percent_vs_opponents(id)
    wins = wins_vs_opponents(id)
    tot_games = tot_games_vs_opponents(id)

    team_ids.each_with_object({}) do |team_id, hash|
      win_percent = (wins[team_id] / tot_games[team_id].to_f).round(2)
      hash[team_id] = win_percent unless win_percent.nan?
    end
  end

  def favorite_opponent(id)
    team_id = win_percent_vs_opponents(id).min_by { |_id, win_percent| win_percent }[0]
    team_name_by_id[team_id]
  end

  def rival(id)
    team_id = win_percent_vs_opponents(id).max_by { |_id, win_percent| win_percent }[0]
    team_name_by_id[team_id]
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
# # puts '_______________________________'
# pp "Winningest coach: #{stat_tracker.winningest_coach('20132014')}"
# pp "Winningest coach: #{stat_tracker.winningest_coach('20142015')}"
# pp "Worst coach: #{stat_tracker.worst_coach('20132014')}"
# pp "Worst coach: #{stat_tracker.worst_coach('20142015')}"
# pp "Most accurate team: #{stat_tracker.most_accurate_team('20132014')}"
# pp "Most accurate team: #{stat_tracker.most_accurate_team('20142015')}"
# pp "Least accurate team: #{stat_tracker.least_accurate_team('20132014')}"
# pp "Least accurate team: #{stat_tracker.least_accurate_team('20142015')}"
# pp "Most tackles: #{stat_tracker.most_tackles('20132014')}"
# pp "Most tackles: #{stat_tracker.most_tackles('20142015')}"
# pp "Fewest tackles: #{stat_tracker.fewest_tackles('20132014')}"
# pp "Fewest tackles: #{stat_tracker.fewest_tackles('20142015')}"
# puts '_______________________________'
# pp stat_tracker.team_info(18)
# pp stat_tracker.best_season(6)
# pp stat_tracker.worst_season(6)
# pp stat_tracker.average_win_percentage(6)
# pp stat_tracker.most_goals_scored(18)
# pp stat_tracker.fewest_goals_scored(18)
# FIX ME -- pp stat_tracker.favorite_opponent(23)
# FIX ME -- pp stat_tracker.rival(23)
