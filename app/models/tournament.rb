# frozen_string_literal: true

# Holds information relevant to assisting users on whether
# to register or not
class Tournament < ApplicationRecord
  enum status: %i[submitted ignored pending published]
  validates :liquipedia_url, uniqueness: true, allow_nil: true, format: { with: %r{\A/ageofempires/} }
  validates :name, uniqueness: true, presence: true

  before_validation :remove_whitespaces
  before_validation :hygienate_liquipedia_url

  private

  def hygienate_liquipedia_url
    self.liquipedia_url = nil unless liquipedia_url.present?
    liquipedia_url&.gsub!(%r{https?://[^/]+}, '')
  end

  def remove_whitespaces
    liquipedia_url&.strip!
    name&.strip!
  end
end
