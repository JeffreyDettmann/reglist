# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Tournaments', type: :request do
  describe 'GET /index' do
    it 'fails if not authenticated' do
      get admin_tournaments_path
      expect(response).to redirect_to(new_user_session_path)
    end

    it 'succeeds if authenticated' do
      user = create(:user)
      sign_in user
      user.confirm
      get admin_tournaments_path
      expect(response).to be_successful
    end
  end
end
