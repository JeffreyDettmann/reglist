# frozen_string_literal: true

# Administrative controllers
module Admin
  # Manages user claims of ownership of tournaments
  class TournamentClaimsController < AdminController
    before_action :make_tournament_claim, only: %i[new create]

    def create
      reasoning = tournament_claim_params[:reasoning]
      @tournament_claim = TournamentClaim.new(tournament: @tournament,
                                              user: current_user,
                                              reasoning:)
      @tournament_claim.errors.add(:reasoning, t(:no_blank)) unless reasoning.present?

      respond_to do |format|
        if reasoning.present? && @tournament_claim.save
          format.html do
            redirect_to admin_tournaments_url(status: @tournament.status),
                        notice: t(:tournament_claim_submitted_for_approval)
          end
          format.json { render :show, status: :created, location: @tournament_claim }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @tournament_claim.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def make_tournament_claim
      @tournament = Tournament.find(params[:tournament_id])
      @tournament_claim = TournamentClaim.new(tournament: @tournament)
    end

    def tournament_claim_params
      params.require(:tournament_claim).permit(:reasoning)
    end
  end
end
