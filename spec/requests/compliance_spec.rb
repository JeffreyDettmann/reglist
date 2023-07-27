# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Compliances', type: :request do
  describe 'GET /privacy_policy' do
    it 'succeeds' do
      get '/compliance/privacy_policy'
      expect(response).to be_successful
    end
  end
end
