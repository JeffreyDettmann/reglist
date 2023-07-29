# frozen_string_literal: true

# Holds information relevant to assisting users on whether
# to register or not
class Tournament < ApplicationRecord
  enum status: { submitted: 0, ignored: 1, pending: 2, published: 3 }

  belongs_to :message, optional: true
  has_many :tournament_claims, dependent: :destroy
  has_many :users, through: :tournament_claims

  validates :liquipedia_url, uniqueness: true, allow_nil: true, format: { with: %r{\A/ageofempires/} }
  validates :name, uniqueness: true, presence: true
  validate :cannot_publish_without_registration_close

  before_validation :remove_whitespaces
  before_validation :hygienate_liquipedia_url

  def owned_by(user)
    return true if user.admin?

    TournamentClaim.exists?(tournament: self, user:, approved: true)
  end

  def waiting_claim_by(user)
    TournamentClaim.exists?(tournament: self, user:, approved: false)
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
    return if flags.blank?

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

  def cannot_publish_without_registration_close
    return unless status == 'published' && registration_close.blank?

    errors.add(:status, "can't by published if no registration close")
  end

  def hygienate_liquipedia_url
    self.liquipedia_url = nil if liquipedia_url.blank?
    liquipedia_url&.gsub!(%r{https?://[^/]+}, '')
  end

  def remove_whitespaces
    liquipedia_url&.strip!
    name&.strip!
  end
end
