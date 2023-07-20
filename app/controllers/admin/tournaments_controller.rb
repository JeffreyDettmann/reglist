# frozen_string_literal: true

# Administrative controllers
module Admin
  # Manages vetting and publication of Tournaments
  class TournamentsController < AdminController
    before_action :set_tournament, except: %i[index new create]
    before_action :new_tournament, only: %i[new create]
    before_action :check_authorization, only: %i[edit update destroy update_status]
    before_action :check_may_publish, only: :update_status
    before_action :check_if_may_request_publication, only: :toggle_request_publication

    def index
      status_filter = params[:status] || :submitted
      @old_tournaments = []
      if current_user.admin?
        if status_filter == 'published'
          @tournaments = Tournament.where(status: status_filter, registration_close: 0.days.ago..).order(:name)
          @old_tournaments = Tournament.where(status: status_filter, registration_close: ...0.days.ago).order(:name)
        else
          @tournaments = Tournament.where(status: status_filter).order(:name)
        end
      else
        @tournaments = current_user_tournaments(status_filter)
      end
    end

    def create
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

    def toggle_request_publication
      if @tournament.message
        remove_message_from_tournament(@tournament)
      else
        add_message_to_tournament(@tournament)
      end
      redirect_to admin_tournaments_url(status: @tournament.status)
    end

    def remove_flag
      if current_user.admin?
        @tournament.update(minus_flags: params[:flag])
      else
        flash[:alert] = 'You are not authorized to remove flags'
      end

      redirect_to(admin_tournaments_url(status: @tournament.status))
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
      return if @tournament.owned_by(current_user)

      redirect_to admin_tournaments_url(status: @tournament.status),
                  alert: 'You are not authorized to update this tournament'
    end

    def check_may_publish
      return if current_user.admin?
      return unless params[:status] == 'published'

      redirect_to admin_tournaments_url(status: @tournament.status),
                  alert: 'You are not authorized to publish tournaments'
    end

    def current_user_tournaments(status)
      Tournament.joins({ tournament_claims: :user })
                .where(status:,
                       users: [current_user])
                .order(:name)
    end

    def check_if_may_request_publication
      unless @tournament.owned_by(current_user)
        return redirect_to(admin_tournaments_url(status: @tournament.status),
                           alert: "You are not authorized to request publication for #{@tournament.name}")
      end

      return if @tournament.status == 'pending'

      redirect_to(admin_tournaments_url(status: @tournament.status),
                  alert: 'You may only request publication for pending tournaments')
    end

    def remove_message_from_tournament(tournament)
      message = tournament.message
      if tournament.update(message: nil, minus_flags: 'publish request') && message.destroy
        flash[:notice] = "Successfully removed request of publication of #{tournament.name}."
      else
        flash[:alert] = "Removal of request for publication of #{tournament.name} failed."
      end
    end

    def add_message_to_tournament(tournament)
      message = Message.new(user: current_user, body: "Please publish #{tournament.name}", requires_action: true)
      if tournament.update(plus_flags: 'publish request', message:)
        flash[:notice] = "Request of publication of #{tournament.name} successful."
      else
        flash[:alert] = "Request of publication of #{tournament.name} failed."
      end
    end
  end
end
