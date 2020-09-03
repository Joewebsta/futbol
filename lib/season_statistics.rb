module SeasonStatistics
  def team_ids
    game_teams.map(&:team_id).sort_by(&:to_i).uniq
  end

  def filter_by_season(season)
    game_teams.find_all { |game| game.game_id[0..3] == season[0..3] }
  end

  def tot_wins_by_coach_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.head_coach] += 1 if game.result == 'WIN'
    end
  end

  def tot_games_by_coach_season(season)
    filter_by_season(season).each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.head_coach] += 1
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
    game.game_id[0..3] == season[0..3]
  end

  def tot_shots_by_team_season(season)
    game_teams.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.team_id] += game.shots.to_i if matches_season?(game, season)
    end
  end

  def tot_goals_by_team_season(season)
    game_teams.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.team_id] += game.goals.to_i if matches_season?(game, season)
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
    game_teams.each_with_object({}) do |game, hash|
      hash.default = 0
      hash[game.team_id] += game.tackles.to_i if matches_season?(game, season)
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
end
