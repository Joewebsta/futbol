class Games
  attr_reader :game_id,
              :season,
              :type,
              :date_time,
              :away_team_id,
              :home_team_id,
              :away_goals,
              :home_goals,
              :venue,
              :venue_link

  def initialize(csv_headers)
    @game_id = csv_headers[:game_id]
    @season = csv_headers[:season]
    @type = csv_headers[:type]
    @date_time = csv_headers[:date_time]
    @away_team_id = csv_headers[:away_team_id]
    @home_team_id = csv_headers[:home_team_id]
    @away_goals = csv_headers[:away_goals].to_i
    @home_goals = csv_headers[:home_goals].to_i
    @venue = csv_headers[:venue]
    @venue_link = csv_headers[:venue_link]
  end
end
