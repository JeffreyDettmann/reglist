# frozen_string_literal: true

# Holds information relevant to assisting users on whether
# to register or not
class Tournament < ApplicationRecord
  enum status: %i[submitted ignored pending published]

  belongs_to :message, optional: true
  has_many :tournament_claims
  has_many :users, through: :tournament_claims

  validates :liquipedia_url, uniqueness: true, allow_nil: true, format: { with: %r{\A/ageofempires/} }
  validates :name, uniqueness: true, presence: true

  before_validation :remove_whitespaces
  before_validation :hygienate_liquipedia_url

  def owned_by(user)
    return true if user.admin?

    TournamentClaim.where(tournament: self, user:, approved: true).exists?
  end

  # Array of flags to add
  def plus_flags(flags_to_add)
    flags_to_add = [flags_to_add] if flags_to_add.is_a?(String)
    old_flags = flags&.split(':') || []
    old_flags += flags_to_add
    self.flags = old_flags.join(':')
  end

  alias plus_flags= plus_flags

  # Array of flags to remove
  def minus_flags(flags_to_remove)
    return unless flags.present?

    flags_to_remove = [flags_to_remove] if flags_to_remove.is_a?(String)
    old_flags = flags.split(':')
    old_flags -= flags_to_remove
    self.flags = old_flags.join(':')
  end

  alias minus_flags= minus_flags

  # Check if has flag
  def flag?(flag)
    (flags || '').split(':').include? flag
  end

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
