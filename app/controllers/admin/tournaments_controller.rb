# frozen_string_literal: true

module Admin
  # Manages vetting and publication of Tournaments
  class TournamentsController < AdminController
    before_action :set_tournament, only: %i[show edit update destroy update_status]
    before_action :new_tournament, only: :new

    def index
      status_filter = params[:status] || :submitted
      @tournaments = Tournament.where(status: status_filter).order(:name)
    end

    def create
      @tournament = Tournament.new
      @tournament.assign_attributes(tournament_params)
      @tournament.status = :pending if current_user.admin?

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
  end
end
