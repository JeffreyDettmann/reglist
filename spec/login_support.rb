# frozen_string_literal: true

module LoginSupport
  def sign_in_admin
    @admin = create(:user, admin: true, confirmed_at: 2.days.ago)
    sign_in @admin
  end
end

RSpec.configure do |config|
  config.include LoginSupport
end
