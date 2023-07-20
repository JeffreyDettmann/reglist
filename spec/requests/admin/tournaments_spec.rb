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

    context 'when logged in as user' do
      let(:tournament_counts) { { submitted: 5, pending: 6, ignored: 5, published: 7 } }
      before do
        @user = create(:user, confirmed_at: 2.days.ago, admin: false)
        sign_in @user
        load_tournaments
      end

      it 'returns the appropriate tournaments when filtered' do
        tnames = Set.new
        tournament_counts.map do |status, count|
          get admin_tournaments_path, params: { status: }
          expect(assigns(:tournaments).size).to eq count + 1
          assigns(:tournaments).each do |tournament|
            expect(tournament.users).to include @user
            expect(tournament.status).to eq status.to_s
            expect(tnames).not_to include tournament.name
            tnames << tournament.name
          end
        end
      end

      def load_tournaments
        index = 0
        tournament_counts.map do |status, count|
          create(:tournament, name: "Unowned tournament #{index}", status:, registration_close: 2.days.ago)
          index += 1
          create(:tournament, name: "Unapproved tournament #{index}",
                              users: [@user],
                              status:, registration_close: 2.days.ago)
          index += 1
          count.times do
            new_tournament = create(:tournament,
                                    name: "Tournament #{index}",
                                    users: [@user],
                                    status:,
                                    registration_close: 2.days.from_now)
            new_tournament.tournament_claims.first.approve!
            index += 1
          end
        end
      end
    end

    context 'when logged in as admin' do
      let(:tournament_counts) { { submitted: 3, pending: 4, ignored: 5, published: 6 } }
      before do
        load_tournaments
        user = create(:user, admin: true)
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

      it 'returns old tournaments separately for published' do
        index = 200
        Tournament.statuses.each do |status, _|
          create(:tournament, name: "Tournament #{index}", status:, registration_close: 2.days.ago)
          index += 1
        end
        tournament_counts.map do |status, count|
          get admin_tournaments_path, params: { status: }
          if status == :published
            expect(assigns(:tournaments).size).to eq count
            expect(assigns(:old_tournaments).size).to eq 1
          else
            expect(assigns(:tournaments).size).to eq count + 1
            expect(assigns(:old_tournaments).size).to eq 0
          end
        end
      end

      def load_tournaments
        index = 0
        tournament_counts.map do |status, count|
          count.times do
            create(:tournament, name: "Tournament #{index}", status:, registration_close: 2.days.from_now)
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

    context 'when logged in as admin' do
      before do
        user = create(:user, admin: true)
        sign_in user
        user.confirm
      end

      it 'sets status to pending' do
        post admin_tournaments_path, params: { tournament: { name: 'Admin Sample Tournament' } }
        tournament = Tournament.last
        expect(tournament.status).to eq 'pending'
      end

      it 'does not create tournament claim' do
        expect do
          post admin_tournaments_path, params: { tournament: { name: 'Admin Sample Tournament' } }
        end.to change(TournamentClaim, :count).by 0
      end
    end

    context 'when logged in as user' do
      before do
        user = create(:user, confirmed_at: 2.days.ago)
        sign_in user
      end

      it 'succeeds if authenticated' do
        expect do
          post admin_tournaments_path, params: { tournament: { name: 'Sample Tournament' } }
        end.to change(Tournament, :count).by(1)
      end

      it 'creates tournament claim' do
        expect do
          post admin_tournaments_path, params: { tournament: { name: 'Sample Tournament' } }
        end.to change(TournamentClaim, :count).by 1
      end

      it 'approves tournament claim' do
        post admin_tournaments_path, params: { tournament: { name: 'Sample Tournament' } }
        tournament = Tournament.last
        assert tournament.tournament_claims.first.approved
      end

      it 'sets status to submitted' do
        post admin_tournaments_path, params: { tournament: { name: 'Sample Tournament' } }
        tournament = Tournament.last
        expect(tournament.status).to eq 'submitted'
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

    context 'when logged in as admin' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user, admin: true)
        sign_in user
        user.confirm
      end

      it 'succeeds if authenticated' do
        get edit_admin_tournament_path(submitted)
        expect(response).to be_successful
      end
    end

    context 'when logged in as user' do
      let(:user) { create(:user, confirmed_at: 2.days.ago) }
      let(:unowned) { create(:tournament, name: 'Submitted Tournament', users: []) }
      let(:unapproved) { create(:tournament, name: 'Submitted Tournament', users: [user]) }
      before do
        sign_in user
      end

      it 'fails if not owned' do
        get edit_admin_tournament_path(unowned)
        expect(response).to redirect_to(admin_tournaments_url(status: unowned.status))
      end

      it 'fails if not approved' do
        get edit_admin_tournament_path(unapproved)
        expect(response).to redirect_to(admin_tournaments_url(status: unapproved.status))
      end

      it 'succeeds if approved' do
        approved = unapproved
        approved.tournament_claims.first.approve!
        get edit_admin_tournament_path(approved)
        expect(response).to be_successful
      end
    end
  end

  describe 'PATCH /update' do
    it 'fails if not authenticated' do
      patch admin_tournament_path(id: 3)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in as admin' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user, admin: true)
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

        it 'redirects to tournaments page based on status' do
          new_name = 'New Name'
          patch admin_tournament_path(submitted), params: { tournament: { name: new_name } }
          expect(response).to redirect_to(admin_tournaments_url(status: submitted.status))
        end
      end

      context 'with blank name' do
        it 'returns unprocessable entity' do
          patch admin_tournament_path(submitted), params: { tournament: { name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'when logged in as user' do
      let(:user) { create(:user, confirmed_at: 2.days.ago) }
      let(:unowned) { create(:tournament, name: 'Submitted Tournament', users: []) }
      let(:unapproved) { create(:tournament, name: 'Submitted Tournament', users: [user]) }
      let(:new_name) { 'New Name' }
      let(:valid_params) { { tournament: { name: new_name } } }
      before do
        sign_in user
      end

      it 'fails if not owned' do
        patch admin_tournament_path(unowned), params: valid_params
        expect(response).to redirect_to(admin_tournaments_url(status: unowned.status))
      end

      it 'fails if not approved' do
        patch admin_tournament_path(unapproved), params: valid_params
        expect(response).to redirect_to(admin_tournaments_url(status: unapproved.status))
      end

      it 'succeeds if approved' do
        approved = unapproved
        approved.tournament_claims.first.approve!
        patch admin_tournament_path(approved), params: valid_params
        approved.reload
        expect(response).to redirect_to(admin_tournaments_url(status: approved.status))
        expect(approved.name).to eq new_name
      end
    end
  end

  describe 'PATCH /update_status' do
    it 'fails if not authenticated' do
      patch update_status_admin_tournament_path(id: 3)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in as user' do
      before do
        @user = create(:user, confirmed_at: 2.days.ago, admin: false)
        sign_in @user
      end

      context 'working with own tournament' do
        before(:each) do
          @submitted = create(:tournament, name: 'Submitted Tournament', users: [@user])
          @submitted.tournament_claims.first.approve!
        end

        it 'updates status with valid status' do
          patch update_status_admin_tournament_path(@submitted), params: { status: :pending }
          @submitted.reload
          expect(@submitted.status).to eq 'pending'
        end

        it 'fails with invalid status' do
          patch update_status_admin_tournament_path(@submitted), params: { status: :invalid_status }
          @submitted.reload
          expect(@submitted.status).to eq 'submitted'
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'redirects to tournaments page of previous status' do
          patch update_status_admin_tournament_path(@submitted), params: { status: :pending }
          expect(response).to redirect_to(admin_tournaments_url(status: @submitted.status))
        end

        it 'cannot publish' do
          patch update_status_admin_tournament_path(@submitted), params: { status: :published }
          expect(response).to redirect_to(admin_tournaments_url(status: @submitted.status))
          @submitted.reload
          expect(@submitted.status).to eq 'submitted'
        end
      end

      context 'working with not approved tournament' do
        let(:submitted) { create(:tournament, name: 'Submitted Tournament', users: [@user]) }

        it 'redirects and does not update' do
          patch update_status_admin_tournament_path(submitted), params: { status: :pending }
          expect(flash[:alert]).to eq 'You are not authorized to update this tournament'
          submitted.reload
          expect(submitted.status).to eq 'submitted'
          expect(response).to redirect_to(admin_tournaments_url(status: submitted.status))
        end
      end

      context 'working with not own tournament' do
        let(:other_user) { create(:user, email: 'other@example.com') }
        before(:each) do
          @submitted = create(:tournament, name: 'Submitted Tournament', users: [other_user])
          @submitted.tournament_claims.first.approve!
        end

        it 'redirects and does not update' do
          patch update_status_admin_tournament_path(@submitted), params: { status: :pending }
          expect(flash[:alert]).to eq 'You are not authorized to update this tournament'
          @submitted.reload
          expect(@submitted.status).to eq 'submitted'
          expect(response).to redirect_to(admin_tournaments_url(status: @submitted.status))
        end
      end
    end

    context 'when logged in as admin' do
      let(:submitted) { create(:tournament, name: 'Submitted Tournament') }
      before do
        user = create(:user, admin: true)
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

      it 'redirects to tournaments page of previous status' do
        patch update_status_admin_tournament_path(submitted), params: { status: :pending }
        expect(response).to redirect_to(admin_tournaments_url(status: submitted.status))
      end
    end
  end

  describe 'PATCH /:id/toggle_request_publication' do
    it 'fails if not authenticated' do
      patch toggle_request_publication_admin_tournament_path(10)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'logged in as user' do
      let(:user) { create(:user, confirmed_at: 2.days.ago) }
      let(:tournament_claims) { [build(:tournament_claim, user:, approved: true)] }
      let(:pending_tournament) { create(:tournament, name: 'Pending', tournament_claims:, status: :pending) }
      let(:submitted_tournament) { create(:tournament, name: 'Submitted', tournament_claims:, status: :submitted) }
      let(:ignored_tournament) { create(:tournament, name: 'Ignored', tournament_claims:, status: :ignored) }
      let(:published_tournament) { create(:tournament, name: 'Published', tournament_claims:, status: :published) }
      let(:requires_action_message) { create(:message, body: 'Publish please', user:, requires_action: true) }
      let(:unowned_tournament) { create(:tournament, name: 'Unowned', status: :pending) }
      let(:requires_action_tournament) do
        create(:tournament,
               name: 'Requires Action',
               tournament_claims:,
               message: requires_action_message,
               plus_flags: 'publish request',
               status: :pending)
      end
      before do
        sign_in user
      end

      it 'adds action_required message when tournament does not have publication request' do
        expect do
          patch toggle_request_publication_admin_tournament_path(pending_tournament)
        end.to change(Message, :count).by 1
        expect(response).to redirect_to(admin_tournaments_url(status: pending_tournament.status))
        expect(pending_tournament.reload.message).to_not be_nil
        assert pending_tournament.message.requires_action?
      end

      it 'adds action_required message when tournament does not have publication request' do
        assert !pending_tournament.flag?('publish request')
        patch toggle_request_publication_admin_tournament_path(pending_tournament)
        assert pending_tournament.reload.flag?('publish request')
      end

      it 'removes action_required message when tournament has publication request' do
        expect(requires_action_tournament.message).to_not be_nil
        expect do
          patch toggle_request_publication_admin_tournament_path(requires_action_tournament)
        end.to change(Message, :count).by(-1)
        expect(requires_action_tournament.reload.message).to be_nil
      end

      it 'removes flag when message when tournament has publication request' do
        assert requires_action_tournament.flag?('publish request')
        patch toggle_request_publication_admin_tournament_path(requires_action_tournament)
        assert !requires_action_tournament.reload.flag?('publish request')
      end

      it 'fails when tournament not owned by user' do
        expect do
          patch toggle_request_publication_admin_tournament_path(unowned_tournament)
        end.to change(Message, :count).by(0)
        expect(flash[:alert]).to_not be_nil
      end

      it 'fails when tournament status submitted' do
        expect do
          patch toggle_request_publication_admin_tournament_path(submitted_tournament)
        end.to change(Message, :count).by(0)
        expect(flash[:alert]).to_not be_nil
      end

      it 'fails when tournament status ignored' do
        expect do
          patch toggle_request_publication_admin_tournament_path(ignored_tournament)
        end.to change(Message, :count).by(0)
        expect(flash[:alert]).to_not be_nil
      end

      it 'fails when tournament status published' do
        expect do
          patch toggle_request_publication_admin_tournament_path(published_tournament)
        end.to change(Message, :count).by(0)
        expect(flash[:alert]).to_not be_nil
      end
    end
  end

  describe 'PATCH /:id/remove_flag' do
    let(:user) { create(:user, confirmed_at: 2.days.ago) }
    let(:requires_action) { create(:tournament, name: 'Requires action', plus_flags: %w[foo bar]) }

    it 'fails if not authenticated' do
      patch remove_flag_admin_tournament_path(requires_action), params: { flag: :foo }
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'logged in as admin' do
      before do
        admin = create(:user, confirmed_at: 2.days.ago, admin: true, email: 'admin@example.com')
        sign_in admin
      end

      it 'removes foo flag but not bar flag' do
        patch remove_flag_admin_tournament_path(requires_action), params: { flag: :foo }
        expect(response).to redirect_to(admin_tournaments_url(status: requires_action.status))
        requires_action.reload
        assert !requires_action.flag?('foo')
        assert requires_action.flag?('bar')
      end
    end
    context 'logged in as user' do
      before do
        sign_in user
      end

      it 'fails' do
        patch remove_flag_admin_tournament_path(requires_action), params: { flag: :foo }
        expect(response).to redirect_to(admin_tournaments_url(status: requires_action.status))
        expect(flash[:alert]).to eq 'You are not authorized to remove flags'
      end
    end
  end
end
