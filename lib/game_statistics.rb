module GameStatistics
  def highest_total_score
    all_total_scores.max
  end

  def lowest_total_score
    all_total_scores.min
  end

  def percentage_home_wins
    tot_games = games.count
    home_wins = games.select { |game| game.home_goals > game.away_goals }.count.to_f
    (home_wins / tot_games).round(2)
  end

  def percentage_visitor_wins
    tot_games = games.count
    visitor_wins = games.select { |game| game.away_goals > game.home_goals }.count.to_f
    (visitor_wins / tot_games).round(2)
  end

  def percentage_ties
    (1.0 - percentage_home_wins - percentage_visitor_wins).round(2)
  end

  def count_of_games_by_season
    games.sort_by(&:season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.season] += 1
    end
  end

  def average_goals_per_game
    tot_games = games.count
    tot_goals = all_total_scores.sum.to_f
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

  private

  def all_total_scores
    games.map { |game| game.away_goals + game.home_goals }
  end

  def count_of_goals_by_season
    games.sort_by(&:season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.season] += (game.away_goals + game.home_goals)
    end
  end
end
