# frozen_string_literal: true

# Join class for users and tournaments
# Must be approved by admin for existing tournament
class TournamentClaim < ApplicationRecord
  belongs_to :tournament
  belongs_to :user

  validates_uniqueness_of :user_id, scope: %i[tournament_id]

  validates_presence_of :reasoning, unless: :approved

  def approve!
    update_attribute(:approved, true)
  end
end
