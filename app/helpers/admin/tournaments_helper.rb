# frozen_string_literal: true

# helpers for admin views
module Admin
  # helpers for tournament views
  module TournamentsHelper
    def name_class(tournament)
      return unless current_user.admin?

      if tournament.tournament_claims.count.positive?
        'text-muted'
      else
        'text-primary'
      end
    end
  end
end
