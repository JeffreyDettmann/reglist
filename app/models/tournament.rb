# frozen_string_literal: true

# Holds information relevant to assisting users on whether
# to register or not
class Tournament < ApplicationRecord
  enum status: %i[submitted ignored pending published]
  validates :liquipedia_url, uniqueness: true, allow_nil: true
  validates :name, uniqueness: true, presence: true

  before_validation :remove_whitespaces

  private

  def remove_whitespaces
    liquipedia_url&.strip!
    name&.strip!
  end
end
