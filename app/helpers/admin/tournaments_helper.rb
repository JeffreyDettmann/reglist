# frozen_string_literal: true

# helpers for admin views
module Admin
  # helpers for tournament views
  module TournamentsHelper
    def name_class(tournament)
      if current_user.admin?
        tournament.tournament_claims.count.positive? ? 'text-muted' : 'text-primary'
      elsif tournament.owned_by(current_user)
        'text-primary'
      elsif tournament.waiting_claim_by(current_user)
        'text-muted'
      end
    end
  end
end
