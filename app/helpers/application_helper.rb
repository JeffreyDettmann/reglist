# frozen_string_literal: true

module ApplicationHelper
  def l_handle_nil(obj, options)
    return nil if obj.nil?

    l(obj, options)
  end

  def ldate(dt, format)
    dt ? l(dt, format:) : nil
  end

  def maybe_link_name(tournament)
    if tournament.info_url.present?
      link_to(tournament.name, tournament.info_url)
    elsif tournament.liquipedia_url.present?
      link_to(tournament.name, "https://liquipedia.net#{tournament.liquipedia_url}")
    else
      tournament.name
    end
  end

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
