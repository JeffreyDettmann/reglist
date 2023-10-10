# frozen_string_literal: true

# Default methods for all controllers
class ApplicationController < ActionController::Base
  # before_action :check_set_allow_cookies
  # before_action :require_allow_cookie
  before_action :determine_locale
  # after_action :maybe_remove_cookies

  def require_allow_cookie
    return if cookies[:allow_cookies]

    redirect_to root_url(pointless: true)
  end

  def check_set_allow_cookies
    cookies[:allow_cookies] = true if params[:accept_cookies] == 'true'
  end

  def determine_locale
    if locale_params
      locale = locale_params
      cookies.permanent[:locale] = locale if cookies[:allow_cookies]
    elsif cookies[:locale]
      locale = cookies[:locale]
    else
      locale = http_accept_language.compatible_language_from(I18n.available_locales)
    end
    I18n.locale = I18n.available_locales.include?(locale&.to_sym) ? locale : I18n.default_locale
  end

  def maybe_remove_cookies
    request.session_options[:skip] = true unless cookies[:allow_cookies]
  end

  def after_sign_in_path_for(resource)
    return super unless current_user.admin? && current_user.sign_in_count == 1

    flash[:notice] = t('please_update_password')
    edit_user_registration_path
  end

  private

  def locale_params
    I18n.available_locales.include?(params[:locale]&.to_sym) ? params[:locale] : nil
  end
end
