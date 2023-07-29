# frozen_string_literal: true

# Join class for users and tournaments
# Must be approved by admin for existing tournament
class TournamentClaim < ApplicationRecord
  belongs_to :tournament
  belongs_to :user

  validates :user_id, uniqueness: { scope: %i[tournament_id] }

  validates :reasoning, presence: { unless: :approved }

  def approve!
    update(approved: true)
  end
end
