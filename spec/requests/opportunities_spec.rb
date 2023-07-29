# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Opportunities' do
  describe 'GET /index' do
    let(:expected_tournament_names) do
      ['published, future registration close',
       'published, registration close today']
    end

    before do
      load_tournaments
      get root_path
    end

    it 'does not require authentication' do
      expect(response).to be_successful
    end

    it 'returns published tournaments with today or later registration close' do
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
      create(:tournament, name: 'published, past registration close', status: :published,
                          registration_close: 1.day.ago)
      create(:tournament, name: 'published, future registration close', status: :published,
                          registration_close: 1.day.from_now)
      create(:tournament, name: 'published, registration close today', status: :published,
                          registration_close: Time.zone.today)
    end

    describe 'handles internationalization' do
      it 'defaults english' do
        get root_path
        expect(response.body).to include(I18n.t(:contact_us, locale: :en))
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :fr))
      end

      it 'with header' do
        get root_path, headers: { 'ACCEPT-LANGUAGE': 'fr' }
        expect(response.body).to include(I18n.t(:contact_us, locale: :fr))
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :en))
      end

      it 'with invalid param' do
        get root_path(locale: 'tlh')
        expect(response.body).to include(I18n.t(:contact_us, locale: :en))
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :fr))
        expect(response.cookies).to be_empty
      end

      it 'with valid param but cookies not accepted' do
        get root_path(locale: 'fr')
        expect(response.body).to include(I18n.t(:contact_us, locale: :fr))
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :en))
        expect(response.cookies).to be_empty
      end

      it 'with valid param but cookies accepted' do
        get root_path(locale: 'fr', accept_cookies: 'true')
        expect(response.body).to include(I18n.t(:contact_us, locale: :fr))
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :en))
        expect(response.cookies['locale']).to eq 'fr'
      end

      it 'with cookie set by previous call' do
        get root_path(locale: 'fr', accept_cookies: 'true')
        get root_path
        expect(response.body).not_to include(I18n.t(:contact_us, locale: :en))
        expect(response.body).to include(I18n.t(:contact_us, locale: :fr))
      end
    end
  end
end
