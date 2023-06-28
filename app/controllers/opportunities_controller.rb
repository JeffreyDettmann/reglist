# frozen_string_literal: true

# Handles requests about upcoming registration opportunities
class OpportunitiesController < ApplicationController
  def index
    @tournaments = Tournament.where(status: :published, registration_close: Date.today..).order(:registration_close)
  end
end
