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

    context 'when logged in' do
      let(:tournament_counts) { { submitted: 3, pending: 4, ignored: 5, published: 6 } }
      before do
        load_tournaments
        user = create(:user)
        sign_in user
        user.confirm
      end

      it 'returns number of submitted without filter' do
        get admin_tournaments_path
        expect(assigns(:tournaments).size).to eq 3
        assigns(:tournaments).each do |tournament|
          expect(tournament.status).to eq 'submitted'
        end
      end

      it 'returns the appropriate tournaments when filtered' do
        tnames = Set.new
        tournament_counts.map do |status, count|
          get admin_tournaments_path, params: { status: }
          expect(assigns(:tournaments).size).to eq count
          assigns(:tournaments).each do |tournament|
            expect(tournament.status).to eq status.to_s
            expect(tnames).not_to include tournament.name
            tnames << tournament.name
          end
        end
      end

      def load_tournaments
        index = 0
        tournament_counts.map do |status, count|
          count.times do
            create(:tournament, name: "Tournament #{index}", status:)
            index += 1
          end
        end
      end
    end
  end
end
