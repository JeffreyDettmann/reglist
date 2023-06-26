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

  describe 'GET /new' do
    it 'fails if not authenticated' do
      get new_admin_tournament_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      before do
        user = create(:user)
        sign_in user
        user.confirm
      end

      it 'succeeds if authenticated' do
        get new_admin_tournament_path
        expect(response).to be_successful
      end
    end
  end

  describe 'POST /create' do
    it 'fails if not authenticated' do
      post admin_tournaments_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      before do
        user = create(:user)
        sign_in user
        user.confirm
      end

      it 'succeeds if authenticated' do
        expect do
          post admin_tournaments_path, params: { tournament: { name: 'Sample Tournament' } }
        end.to change(Tournament, :count).by(1)
      end

      context 'with existing liquipedia url' do
        let(:url) { '/ageofempires/coolio' }
        before do
          create(:tournament, name: 'Existing', liquipedia_url: url)
        end

        it 'does not create new tournament' do
          expect do
            post admin_tournaments_path, params: { tournament: { name: 'Coolio', liquipedia_url: url } }
          end.to change(Tournament, :count).by(0)
        end

        it 'returns unprocessable_entity' do
          post admin_tournaments_path, params: { tournament: { name: 'Coolio', liquipedia_url: url } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET /edit' do
    it 'fails if not authenticated' do
      get edit_admin_tournament_path(id: 3)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user)
        sign_in user
        user.confirm
      end

      it 'succeeds if authenticated' do
        get edit_admin_tournament_path(submitted)
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    it 'fails if not authenticated' do
      patch admin_tournament_path(id: 3)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user)
        sign_in user
        user.confirm
      end

      context 'with valid parameters' do
        it 'updates the requested tournament' do
          new_name = 'New Name'
          patch admin_tournament_path(submitted), params: { tournament: { name: new_name } }
          submitted.reload
          expect(submitted.name).to eq new_name
        end

        it 'redirects to tournaments page' do
          new_name = 'New Name'
          patch admin_tournament_path(submitted), params: { tournament: { name: new_name } }
          expect(response).to redirect_to(admin_tournaments_url)
        end
      end

      context 'with blank name' do
        it 'returns unprocessable entity' do
          patch admin_tournament_path(submitted), params: { tournament: { name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'PATCH /update_status' do
    it 'fails if not authenticated' do
      patch update_status_admin_tournament_path(id: 3)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user)
        sign_in user
        user.confirm
      end

      it 'updates status with valid status' do
        patch update_status_admin_tournament_path(submitted), params: { status: :pending }
        submitted.reload
        expect(submitted.status).to eq 'pending'
      end

      it 'fails with invalid status' do
        patch update_status_admin_tournament_path(submitted), params: { status: :invalid_status }
        submitted.reload
        expect(submitted.status).to eq 'submitted'
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
