# frozen_string_literal: true

module ApplicationHelper
  def divided_content(content)
    content&.gsub("\n", '<br/>')
  end
  
  def class_for_tournament(tournament)
    if tournament.game == 'Age of Mythology'
      'aom'
    elsif tournament.game
      "aoe#{tournament.game[15..].downcase}"
    end
  end
end
