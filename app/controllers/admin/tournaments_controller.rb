# frozen_string_literal: true

module Admin
  # Manages vetting and publication of Tournaments
  class TournamentsController < AdminController
    def index
      status_filter = params[:status] || :submitted
      @tournaments = Tournament.where(status: status_filter)
    end
  end
end
