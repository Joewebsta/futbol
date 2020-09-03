module TeamStatistics
  def team_info(id)
    team_information = teams.find { |team| team.team_id == id.to_s }
    {
      team_id: team_information.team_id,
      franchise_id: team_information.franchise_id,
      team_name: team_information.team_name,
      abbreviation: team_information.abbreviation,
      link: team_information.link
    }
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

  def seasons
    games.map(&:season).sort_by(&:to_i).uniq
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
