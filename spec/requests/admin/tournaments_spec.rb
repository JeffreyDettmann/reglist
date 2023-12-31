# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Tournaments' do
  context 'without accept cookie' do
    it 'redirects home with message' do
      get admin_tournaments_path
      expect(response).to redirect_to(root_url(pointless: true))
    end
  end

  context 'with accept cookie' do
    before do
      get compliance_dmca_path, params: { accept_cookies: 'true' }
    end

    describe 'GET /index' do
      it 'fails if not authenticated' do
        get admin_tournaments_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'succeeds if authenticated' do
        user = create(:user, confirmed_at: 2.days.ago)
        sign_in user
        get admin_tournaments_path
        expect(response).to be_successful
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:tournament_counts) { { submitted: 5, pending: 6, ignored: 5, published: 7 } }

        before do
          sign_in user
          load_tournaments
        end

        shared_examples 'returns tournaments based on status' do |status|
          it 'returns the correct number' do
            get admin_tournaments_path, params: { status: }
            expect(assigns(:tournaments).size).to eq tournament_counts[status] + 2
          end

          it 'returns correct status' do
            get admin_tournaments_path, params: { status: }
            assigns(:tournaments).each do |tournament|
              expect(tournament.status).to eq status.to_s
            end
          end

          it 'marks ownership correctly' do
            get admin_tournaments_path, params: { status: }
            assigns(:tournaments).each do |tournament|
              expect(tournament.owned_by(user)).to eq (tournament.name =~ /^Tournament/).present?
            end
          end
        end

        include_examples 'returns tournaments based on status', :submitted
        include_examples 'returns tournaments based on status', :pending
        include_examples 'returns tournaments based on status', :ignored
        include_examples 'returns tournaments based on status', :published

        def load_tournaments
          index = 0
          tournament_counts.map do |status, count|
            create(:tournament, name: "Unowned tournament #{index}", status:, registration_close: 2.days.ago)
            index += 1
            claim = build(:tournament_claim, user:, reasoning: :reasons)
            create(:tournament,
                   name: "Unapproved tournament #{index}",
                   tournament_claims: [claim],
                   status:, registration_close: 2.days.ago)
            index += 1
            count.times do
              claim = build(:tournament_claim, user:, approved: true)
              create(:tournament,
                     name: "Tournament #{index}",
                     tournament_claims: [claim],
                     status:,
                     registration_close: 2.days.from_now)
              index += 1
            end
          end
        end
      end

      context 'when logged in as admin' do
        let(:tournament_counts) { { submitted: 3, pending: 4, ignored: 5, published: 6 } }

        before do
          load_tournaments
          sign_in_admin
        end

        shared_examples 'returns tournaments based on status' do |status|
          it 'returns the correct number' do
            get admin_tournaments_path, params: { status: }
            expect(assigns(:tournaments).size).to eq tournament_counts[status]
          end

          it 'returns correct status' do
            get admin_tournaments_path, params: { status: }
            assigns(:tournaments).each do |tournament|
              expect(tournament.status).to eq status.to_s
            end
          end
        end

        include_examples 'returns tournaments based on status', :submitted
        include_examples 'returns tournaments based on status', :pending
        include_examples 'returns tournaments based on status', :ignored
        include_examples 'returns tournaments based on status', :published

        it 'returns number of submitted without filter' do
          get admin_tournaments_path
          assigns(:tournaments).each do |tournament|
            expect(tournament.status).to eq 'submitted'
          end
        end

        it 'separates past tournaments for published`' do
          get admin_tournaments_path, params: { status: :published }
          assert assigns(:old_tournaments).size == 1
          expect(assigns(:old_tournaments).first.name).to eq 'Old Tournament'
        end

        def load_tournaments
          index = 0
          create(:tournament, name: 'Old Tournament', status: :published, registration_close: 2.days.ago)
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
          sign_in_user
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
          sign_in_admin
        end

        it 'sets status to pending' do
          post admin_tournaments_path, params: { tournament: { name: 'Admin Sample Tournament' } }
          tournament = Tournament.last
          expect(tournament.status).to eq 'pending'
        end

        it 'does not create tournament claim' do
          expect do
            post admin_tournaments_path, params: { tournament: { name: 'Admin Sample Tournament' } }
          end.not_to change(TournamentClaim, :count)
        end
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:url) { '/ageofempires/coolio' }
        let(:valid_params) { { tournament: { name: 'Sample Tournament', liquipedia_url: '/ageofempires/valid' } } }

        before do
          create(:tournament, name: 'Existing', liquipedia_url: url)
          sign_in user
        end

        it 'succeeds if authenticated' do
          expect do
            post admin_tournaments_path, params: valid_params
          end.to change(Tournament, :count).by(1)
        end

        it 'creates tournament claim' do
          expect do
            post admin_tournaments_path, params: valid_params
          end.to change(TournamentClaim, :count).by 1
        end

        it 'approves tournament claim' do
          post admin_tournaments_path, params: valid_params
          tournament = Tournament.last
          expect(tournament.tournament_claims.first).to be_approved
        end

        it 'sets status to submitted' do
          post admin_tournaments_path, params: valid_params
          tournament = Tournament.last
          expect(tournament.status).to eq 'submitted'
        end

        it 'does not create new tournament if liquipeda url exists' do
          expect do
            post admin_tournaments_path, params: { tournament: { name: 'Coolio', liquipedia_url: url } }
          end.not_to change(Tournament, :count)
        end

        it 'returns unprocessable_entity if liquipedia url exists' do
          post admin_tournaments_path, params: { tournament: { name: 'Coolio', liquipedia_url: url } }
          expect(response).to have_http_status(:unprocessable_entity)
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
          sign_in_admin
        end

        it 'succeeds if authenticated' do
          get edit_admin_tournament_path(submitted)
          expect(response).to be_successful
        end
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:unowned) { create(:tournament, name: 'Submitted Tournament', users: []) }
        let(:claim) { build(:tournament_claim, user:, reasoning: :reasons) }
        let(:unapproved) { create(:tournament, name: 'Submitted Tournament', tournament_claims: [claim]) }

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
          sign_in_admin
        end

        it 'updates the requested tournament with valid parameters' do
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

        it 'returns unprocessable entity with blank name' do
          patch admin_tournament_path(submitted), params: { tournament: { name: '' } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:unowned) { create(:tournament, name: 'Submitted Tournament', users: []) }
        let(:claim) { build(:tournament_claim, user:, reasoning: :reasons) }
        let(:unapproved) { create(:tournament, name: 'Submitted Tournament', tournament_claims: [claim]) }
        let(:valid_params) { { tournament: { name: 'New Name' } } }

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
          expect(approved.name).to eq 'New Name'
        end
      end
    end

    describe 'PATCH /update_status' do
      it 'fails if not authenticated' do
        patch update_status_admin_tournament_path(id: 3)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as user working with own tournament' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:claim) { build(:tournament_claim, user:, approved: true) }
        let(:submitted) { create(:tournament, name: 'Submitted Tournament', tournament_claims: [claim]) }

        before do
          sign_in user
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

        it 'cannot publish' do
          patch update_status_admin_tournament_path(submitted), params: { status: :published }
          expect(response).to redirect_to(admin_tournaments_url(status: submitted.status))
          submitted.reload
          expect(submitted.status).to eq 'submitted'
        end
      end

      context 'when logged in as user working with not approved tournament' do
        let(:claim) { build(:tournament_claim, user:, reasoning: :reasons) }
        let(:submitted) { create(:tournament, name: 'Submitted Tournament', tournament_claims: [claim]) }
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }

        before do
          sign_in user
        end

        it 'redirects and does not update' do
          patch update_status_admin_tournament_path(submitted), params: { status: :pending }
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
          submitted.reload
          expect(submitted.status).to eq 'submitted'
        end
      end

      context 'when working with not own tournament' do
        let(:other_user) { create(:user, email: 'other@example.com') }
        let(:claim) { build(:tournament_claim, user: other_user, reasoning: :reasons) }
        let(:submitted) { create(:tournament, name: 'Submitted Tournament', tournament_claims: [claim]) }

        before do
          sign_in_user
        end

        it 'redirects and does not update' do
          patch update_status_admin_tournament_path(submitted), params: { status: :pending }
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
          submitted.reload
          expect(submitted.status).to eq 'submitted'
        end
      end

      context 'when logged in as admin' do
        let(:submitted) { create(:tournament, name: 'Submitted Tournament') }

        before do
          sign_in_admin
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

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:tournament_claims) { [build(:tournament_claim, user:, approved: true)] }
        let(:tournament) do
          build(:tournament, name: 'Tournament', registration_close: 1.day.from_now, tournament_claims:)
        end
        let(:requires_action_message) { create(:message, body: 'Publish please', user:, requires_action: true) }
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

        it 'redirects to tournament list with appropriate status' do
          tournament.save
          patch toggle_request_publication_admin_tournament_path(tournament)
          expect(response).to redirect_to(admin_tournaments_url(status: tournament.status))
        end

        it 'adds action_required message' do
          tournament.update(status: :pending)
          expect do
            patch toggle_request_publication_admin_tournament_path(tournament)
          end.to change(Message, :count).by 1
          expect(tournament.reload.message).not_to be_nil
        end

        it 'flags action_required message' do
          tournament.update(status: :pending)
          assert !tournament.flag?('publish request')
          patch toggle_request_publication_admin_tournament_path(tournament)
          expect(tournament.reload).to be_flag('publish request')
          assert tournament.message.requires_action?
        end

        it 'removes action_required message when tournament has publication request' do
          assert requires_action_tournament.message.present?
          expect do
            patch toggle_request_publication_admin_tournament_path(requires_action_tournament)
          end.to change(Message, :count).by(-1)
          expect(requires_action_tournament.reload.message).to be_nil
        end

        it 'removes flag when message when tournament has publication request' do
          assert requires_action_tournament.flag?('publish request')
          patch toggle_request_publication_admin_tournament_path(requires_action_tournament)
          expect(requires_action_tournament.reload).not_to be_flag('publish request')
        end

        it 'fails when tournament not owned by user' do
          unowned_tournament = create(:tournament, name: 'Unowned', status: :pending)
          expect do
            patch toggle_request_publication_admin_tournament_path(unowned_tournament)
          end.not_to change(Message, :count)
          expect(flash[:alert]).not_to be_nil
        end

        it 'fails when tournament status submitted' do
          tournament.update(status: :submitted)
          expect do
            patch toggle_request_publication_admin_tournament_path(tournament)
          end.not_to change(Message, :count)
          expect(flash[:alert]).not_to be_nil
        end

        it 'fails when tournament status ignored' do
          tournament.update(status: :ignored)
          expect do
            patch toggle_request_publication_admin_tournament_path(tournament)
          end.not_to change(Message, :count)
          expect(flash[:alert]).not_to be_nil
        end

        it 'fails when tournament status published' do
          tournament.update(status: :published)
          expect do
            patch toggle_request_publication_admin_tournament_path(tournament)
          end.not_to change(Message, :count)
          expect(flash[:alert]).not_to be_nil
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

      context 'when logged in as admin' do
        before do
          sign_in_admin
        end

        it 'removes foo flag but not bar flag' do
          patch remove_flag_admin_tournament_path(requires_action), params: { flag: :foo }
          expect(response).to redirect_to(admin_tournaments_url(status: requires_action.status))
          requires_action.reload
          assert !requires_action.flag?('foo')
          assert requires_action.flag?('bar')
        end
      end

      context 'when logged in as user' do
        before do
          sign_in user
        end

        it 'fails' do
          patch remove_flag_admin_tournament_path(requires_action), params: { flag: :foo }
          expect(response).to redirect_to(admin_tournaments_url(status: requires_action.status))
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
        end
      end
    end
  end
end
