# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Opportunities', type: :request do
  describe 'GET /index' do
    it 'does not require authentication' do
      get root_path
      expect(response).to be_successful
    end

    it 'returns published tournaments with today or later registration close' do
      expected_tournament_names = ['published, future registration close',
                                   'published, registration close today']
      load_tournaments
      get root_path
      tournaments = assigns(:tournaments)
      expect(tournaments.size).to eq 2
      tournaments.each do |tournament|
        expect(expected_tournament_names).to include(tournament.name)
      end
    end

    def load_tournaments
      create(:tournament, name: 'not published, no registration close', status: :pending)
      create(:tournament, name: 'not published, past registration close', status: :pending,
                          registration_close: 1.day.ago)
      create(:tournament, name: 'not published, future registration close', status: :pending,
                          registration_close: 1.day.from_now)
      create(:tournament, name: 'published, no registration close', status: :published)
      create(:tournament, name: 'published, past registration close', status: :published,
                          registration_close: 1.day.ago)
      create(:tournament, name: 'published, future registration close', status: :published,
                          registration_close: 1.day.from_now)
      create(:tournament, name: 'published, registration close today', status: :published,
                          registration_close: Date.today)
    end
  end
end
