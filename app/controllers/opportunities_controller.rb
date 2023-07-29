# frozen_string_literal: true

# Handles requests about upcoming registration opportunities
class OpportunitiesController < ApplicationController
  skip_before_action :require_allow_cookie

  def index
    @tournaments = Tournament.where(status: :published,
                                    registration_close: Time.zone.today..).order(:registration_close)
  end
end
