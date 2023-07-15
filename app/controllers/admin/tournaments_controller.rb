# frozen_string_literal: true

# Administrative controllers
module Admin
  # Manages vetting and publication of Tournaments
  class TournamentsController < AdminController
    before_action :set_tournament, only: %i[show edit update destroy update_status]
    before_action :new_tournament, only: :new
    before_action :check_authorization, only: %i[edit update destroy update_status]
    before_action :check_can_publish, only: :update_status

    def index
      status_filter = params[:status] || :submitted
      @old_tournaments = @unapproved_tournaments = []
      if current_user.admin?
        if status_filter == 'published'
          @tournaments = Tournament.where(status: status_filter, registration_close: 0.days.ago..).order(:name)
          @old_tournaments = Tournament.where(status: status_filter, registration_close: ...0.days.ago).order(:name)
        else
          @tournaments = Tournament.where(status: status_filter).order(:name)
        end
      else
        @tournaments = current_user_tournaments(status_filter, true)
        @unapproved_tournaments = current_user_tournaments(status_filter, false)
      end
    end

    def create
      @tournament = Tournament.new
      @tournament.assign_attributes(tournament_params)
      if current_user.admin?
        @tournament.status = :pending
      else
        claim = TournamentClaim.new(user: current_user, approved: true)
        @tournament.tournament_claims << claim
      end

      respond_to do |format|
        if @tournament.save
          format.html { redirect_to admin_tournaments_url, notice: 'Tournament successfully created.' }
          format.json { render :show, status: :created, location: @tournament }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @tournament.errors, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @tournament.update(tournament_params)
          format.html do
            redirect_to admin_tournaments_url(status: @tournament.status),
                        notice: "#{@tournament.name} was successfully updated."
          end
          format.json { render :show, status: :ok, location: @tournament }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tournament.errors, status: :unprocessable_entity }
        end
      end
    end

    def update_status
      old_status = @tournament.status
      status_valid = Tournament.statuses.include?(params[:status])
      respond_to do |format|
        if status_valid && @tournament.update(status: params[:status])
          format.html do
            redirect_to admin_tournaments_url(status: old_status),
                        notice: "#{@tournament.name} was successfully updated."
          end
          format.json { render :show, status: :ok, location: @tournament }
        else
          @tournament.errors.add(:status, 'Invalid Status')
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @tournament.errors, status: :unprocessable_entity }
        end
      end
    end

    private

    def new_tournament
      @tournament = Tournament.new(game: 'Age of Empires II')
    end

    def set_tournament
      @tournament = Tournament.find(params[:id])
    end

    def tournament_params
      status = params.dig(:tournament, :status)
      if @tournament && !Tournament.statuses.include?(status)
        @tournament.errors.add(:status, 'Invalid Status')
        params[:status] = nil
      end
      params.require(:tournament).permit!
    end

    def check_authorization
      return if current_user.admin? || current_user.tournaments.approved.include?(@tournament)

      redirect_to admin_tournaments_url(status: @tournament.status),
                  alert: 'You are not authorized to update this tournament'
    end

    def check_can_publish
      return if current_user.admin?
      return unless params[:status] == 'published'

      redirect_to admin_tournaments_url(status: @tournament.status),
                  alert: 'You are not authorized to publish tournaments'
    end

    def current_user_tournaments(status, approved)
      Tournament.joins({ tournament_claims: :user })
                .where(status:,
                       'tournament_claims.approved' => approved,
                       users: [current_user])
                .order(:name)
    end
  end
end
