# frozen_string_literal: true

# Default methods for all controllers
class ApplicationController < ActionController::Base
  def after_sign_in_path_for(_resource)
    return unless current_user.admin? && current_user.sign_in_count == 1

    flash[:notice] = 'Please update your password'
    edit_user_registration_path
  end
end
