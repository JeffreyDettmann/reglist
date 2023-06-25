# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Opportunities', type: :request do
  describe 'GET /index' do
    it 'does not require authentication' do
      get root_path
      expect(response).to be_successful
    end
  end
end
