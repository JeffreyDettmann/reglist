# frozen_string_literal: true

# Default methods for all controllers related to administration
class AdminController < ApplicationController
  before_action :authenticate_user!
end
