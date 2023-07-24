# frozen_string_literal: true

# Administrative controllers
module Admin
  # Manages user claims of ownership of tournaments
  class TournamentClaimsController < AdminController
    before_action :make_tournament_claim, only: %i[new create]
    before_action :load_tournament_claim, only: %i[edit update approve destroy]
    before_action :check_authorization, only: %i[edit update destroy]

    def index
      if current_user.admin?
        @approved_claims = TournamentClaim.where(approved: true).where.not(reasoning: '').preload(:tournament, :user)
        @unapproved_claims = TournamentClaim.where(approved: false).where.not(reasoning: '').preload(:tournament, :user)
      else
        @approved_claims = TournamentClaim.where(approved: true, user: current_user).preload(:tournament)
        @unapproved_claims = TournamentClaim.where(approved: false, user: current_user).preload(:tournament)
      end
    end

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

    def update
      if @tournament_claim.update(tournament_claim_params)
        flash[:notice] = t(:thing_updated, name: 'reasoning')
        redirect_to(admin_tournament_claims_url)
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      flash[:notice] = t(:thing_deleted, name: 'claim') if @tournament_claim.destroy
      redirect_to(admin_tournament_claims_url)
    end

    def approve
      unless current_user.admin?
        return redirect_to(admin_tournament_claims_url,
                           alert: t(:not_authorized))
      end

      if params[:approved] == 'true'
        @tournament_claim.approve!
      else
        @tournament_claim.update_attribute(:approved, false)
      end
      redirect_to(admin_tournament_claims_url,
                  notice: t(:thing_updated, name: :claim))
    end

    private

    def check_authorization
      return if current_user.admin? || @tournament_claim.user == current_user

      redirect_to(admin_tournament_claims_url, alert: t(:not_authorized))
    end

    def load_tournament_claim
      @tournament_claim = TournamentClaim.find(params[:id])
    end

    def make_tournament_claim
      @tournament = Tournament.find(params[:tournament_id])
      @tournament_claim = TournamentClaim.new(tournament: @tournament)
    end

    def tournament_claim_params
      params.require(:tournament_claim).permit(:reasoning)
    end
  end
end
