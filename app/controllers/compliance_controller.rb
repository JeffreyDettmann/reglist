# frozen_string_literal: true

# Static files for policy docs
class ComplianceController < ApplicationController
  skip_before_action :require_allow_cookie
end
