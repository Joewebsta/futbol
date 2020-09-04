module LeagueStatistics
  def count_of_teams
    teams.count
  end

  def best_offense
    best_offense_id = avg_goals_per_game_by_team(game_teams).max_by { |_id, goals| goals }[0]
    team_name_by_id[best_offense_id]
  end

  def worst_offense
    worst_offense_id = avg_goals_per_game_by_team(game_teams).min_by { |_id, goals| goals }[0]
    team_name_by_id[worst_offense_id]
  end

  def highest_scoring_visitor
    away_games_arr = filter_by_hoa('away')
    highest_scoring_visitor_by_id = avg_goals_per_game_by_team(away_games_arr).max_by { |_id, goals| goals }[0]
    team_name_by_id[highest_scoring_visitor_by_id]
  end

  def highest_scoring_home_team
    home_games = filter_by_hoa('home')
    high_scoring_home_team_id = avg_goals_per_game_by_team(home_games).max_by { |_id, goals| goals }[0]
    team_name_by_id[high_scoring_home_team_id]
  end

  def lowest_scoring_visitor
    away_games_arr = filter_by_hoa('away')
    lowest_scoring_visitor_by_id = avg_goals_per_game_by_team(away_games_arr).min_by { |_id, goals| goals }[0]
    team_name_by_id[lowest_scoring_visitor_by_id]
  end

  def lowest_scoring_home_team
    home_games = filter_by_hoa('home')
    low_scoring_home_team_id = avg_goals_per_game_by_team(home_games).min_by { |_id, goals| goals }[0]
    team_name_by_id[low_scoring_home_team_id]
  end

  private

  def tot_goals_by_team(data)
    data.sort_by { |game| game.team_id.to_i }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.team_id] += game.goals.to_i
    end
  end

  def tot_games_by_team(data)
    data.sort_by { |game| game.team_id.to_i }.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.team_id] += 1
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
    teams.sort_by { |team| team.team_id.to_i }.each_with_object({}) do |team, hash|
      hash[team.team_id] = team.team_name
    end
  end

  def filter_by_hoa(type)
    game_teams.select { |game| game.hoa == type }
  end
end
