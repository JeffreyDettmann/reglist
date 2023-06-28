# frozen_string_literal: true

module ApplicationHelper
  def class_for_tournament(tournament)
    "aoe#{tournament.game[15..].downcase}" if tournament.game
  end
end
