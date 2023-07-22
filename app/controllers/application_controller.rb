# frozen_string_literal: true

# Default methods for all controllers
class ApplicationController < ActionController::Base
  around_action :switch_locale

  def switch_locale(&)
    locale = http_accept_language.compatible_language_from(I18n.available_locales) || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  def after_sign_in_path_for(resource)
    return super unless current_user.admin? && current_user.sign_in_count == 1

    flash[:notice] = t('please_update_password')
    edit_user_registration_path
  end
end
