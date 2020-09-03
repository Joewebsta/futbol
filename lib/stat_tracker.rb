require 'csv'
require './lib/games_collection'
require './lib/game_statistics'
require './lib/league_statistics'
require './lib/season_statistics'

class StatTracker
  include GameStatistics
  include LeagueStatistics
  include SeasonStatistics

  attr_reader :games, :team_data, :game_teams_data

  def initialize(data)
    @games = data[:games]
    @team_data = data[:teams]
    @game_teams_data = data[:game_teams]
  end

  def self.from_csv(locations)
    data = {}
    data[:games] = GamesCollection.from_csv(locations[:games])
    data[:teams] = CSV.read(locations[:teams], headers: true, header_converters: :symbol)
    data[:game_teams] = CSV.read(locations[:game_teams], headers: true, header_converters: :symbol)
    StatTracker.new(data)
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
    games.map(&:season).sort_by(&:to_i).uniq
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
    games.find_all { |game| game.home_team_id == id.to_s || game.away_team_id == id.to_s }
  end

  def wins_vs_opponents(id)
    home_and_away_games(id).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.away_team_id] += 1 if (game.home_goals < game.away_goals) && game.away_team_id != id.to_s
      hash[game.home_team_id] += 1 if (game.away_goals < game.home_goals) && game.home_team_id != id.to_s
    end
  end

  def tot_games_vs_opponents(id)
    home_and_away_games(id).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.away_team_id] += 1 unless game.away_team_id == id.to_s
      hash[game.home_team_id] += 1 unless game.home_team_id == id.to_s
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
# puts '_______________________________'
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
