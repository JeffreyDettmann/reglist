# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::TournamentClaims' do
  context 'without accept cookie' do
    it 'redirects home with message' do
      get admin_tournament_claims_path
      expect(response).to redirect_to(root_url(pointless: true))
    end
  end

  context 'with accept cookie' do
    before do
      get compliance_dmca_path, params: { accept_cookies: 'true' }
    end

    describe 'GET /index' do
      it 'fails if not authenticated' do
        get admin_tournament_claims_path
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as admin' do
        let(:user) { create(:user) }

        before do
          sign_in_admin
          load_claims
        end

        it 'only returns claims with reasoning' do
          get admin_tournament_claims_path
          assigns(:approved_claims).each { |claim| expect(claim.reasoning).to be_present }
          assigns(:unapproved_claims).each { |claim| expect(claim.reasoning).to be_present }
        end

        it 'separates claims by approval' do
          get admin_tournament_claims_path
          assert assigns(:approved_claims).size == 1
          assert assigns(:unapproved_claims).size == 1
          expect(assigns(:approved_claims).first).to be_approved
          expect(assigns(:unapproved_claims).first).not_to be_approved
        end

        def load_claims
          approved_reasonless = build(:tournament_claim, user:, approved: true)
          approved_reasoned = build(:tournament_claim, user:, approved: true, reasoning: :reasons)
          unapproved_reasoned = build(:tournament_claim, user:, approved: false, reasoning: :reasons)
          create(:tournament, name: 'Approved Reasonless', tournament_claims: [approved_reasonless])
          create(:tournament, name: 'Approved Reasoned', tournament_claims: [approved_reasoned])
          create(:tournament, name: 'Unapproved Reasoned', tournament_claims: [unapproved_reasoned])
        end
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:other_user) { create(:user) }

        before do
          sign_in user
          load_claims
        end

        it 'only returns users claims' do
          get admin_tournament_claims_path
          assert(assigns(:approved_claims).size == 1)
          assert(assigns(:unapproved_claims).size == 1)
          assigns(:approved_claims).each { |claim| expect(claim.user).to eq user }
          assigns(:unapproved_claims).each { |claim| expect(claim.user).to eq user }
        end

        it 'separates claims by approval' do
          get admin_tournament_claims_path
          assert(assigns(:approved_claims).size == 1)
          assert(assigns(:unapproved_claims).size == 1)
          expect(assigns(:approved_claims)).to all be_approved
          assigns(:unapproved_claims).each { |claim| expect(claim).not_to be_approved }
        end

        def load_claims
          [build(:tournament_claim, user:, approved: false, reasoning: :reasons),
           build(:tournament_claim, user:, approved: true),
           build(:tournament_claim, user: other_user, approved: false, reasoning: :reasons),
           build(:tournament_claim, user: other_user, approved: true)].each_with_index do |claim, idx|
            create(:tournament, name: "Tournament #{idx}",
                                tournament_claims: [claim])
          end
        end
      end
    end

    describe 'GET /new' do
      let(:tournament) { create(:tournament, name: :foo) }

      it 'fails if not authenticated' do
        get new_admin_tournament_tournament_claim_path(tournament)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in' do
        before do
          sign_in_user
        end

        it 'succeeds if authenticated' do
          get new_admin_tournament_tournament_claim_path(tournament)
          expect(response).to be_successful
        end
      end
    end

    describe 'POST /create' do
      let(:tournament) { create(:tournament, name: :foo) }

      it 'fails if not authenticated' do
        post admin_tournament_tournament_claims_path(tournament)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:other_user) { create(:user, confirmed_at: 2.days.ago) }
        let(:valid_params) { { tournament_claim: { reasoning: :reasons } } }
        let(:approved_params) { { tournament_claim: { approved: true, reasoning: :reasons } } }

        before do
          sign_in user
        end

        it 'claims unclaimed tournament' do
          expect do
            post admin_tournament_tournament_claims_path(tournament), params: valid_params
          end.to change(TournamentClaim, :count).by(1)
          assert !TournamentClaim.last.approved?
        end

        it 'does not claim tournament with existing user claim' do
          create(:tournament_claim, user:, tournament:, reasoning: :reasons)
          expect do
            post admin_tournament_tournament_claims_path(tournament), params: valid_params
          end.not_to change(TournamentClaim, :count)
        end

        it 'claims tournament claimed by someone else' do
          create(:tournament_claim, user: other_user, tournament:, reasoning: :reasons)
          expect do
            post admin_tournament_tournament_claims_path(tournament), params: valid_params
          end.to change(TournamentClaim, :count).by(1)
          assert !TournamentClaim.last.approved?
        end

        it 'fails with blank reason' do
          expect do
            post admin_tournament_tournament_claims_path(tournament), params: { tournament_claim: { reasoning: '' } }
          end.not_to change(TournamentClaim, :count)
        end

        it 'does not approve claim even with approved params' do
          expect do
            post admin_tournament_tournament_claims_path(tournament), params: approved_params
          end.to change(TournamentClaim, :count).by(1)
          expect(TournamentClaim.last).not_to be_approved
        end
      end
    end

    describe 'GET /edit' do
      it 'fails if not authenticated' do
        get edit_admin_tournament_claim_path(27)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:other_user) { create(:user) }
        let(:tournament) { create(:tournament, name: :foo) }

        before do
          sign_in user
        end

        it 'allows edit own claim' do
          claim = create(:tournament_claim, user:, tournament:, reasoning: :reasons)
          get edit_admin_tournament_claim_path(claim)
          expect(response).to be_successful
        end

        it 'forbids edit others claim' do
          claim = create(:tournament_claim, user: other_user, tournament:, reasoning: :reasons)
          get edit_admin_tournament_claim_path(claim)
          expect(response).to redirect_to(admin_tournament_claims_path)
        end
      end
    end

    describe 'PATCH /update' do
      it 'fails if not authenticated' do
        patch admin_tournament_claim_path(27)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:tournament) { create(:tournament, name: :foo) }
        let(:reasoning) { 'updated reasons' }
        let(:valid_params) { { tournament_claim: { reasoning: } } }
        let(:approved_params) { { tournament_claim: { approved: true, reasoning: } } }

        before do
          sign_in user
        end

        it 'allows update own claim' do
          claim = create(:tournament_claim, user:, tournament:, reasoning: :reasons)
          patch admin_tournament_claim_path(claim), params: valid_params
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(claim.reload.reasoning).to eq reasoning
        end

        it 'forbids update others claim' do
          claim = create(:tournament_claim, user: create(:user), tournament:, reasoning: :reasons)
          patch admin_tournament_claim_path(claim), params: valid_params
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
        end

        it 'does not update approval' do
          claim = create(:tournament_claim, user:, tournament:, reasoning: :reasons)
          patch admin_tournament_claim_path(claim), params: approved_params
          expect(claim.reload).not_to be_approved
          expect(claim.reload.reasoning).to eq reasoning
        end
      end
    end

    describe 'DELETE /destroy' do
      it 'fails if not authenticated' do
        delete admin_tournament_claim_path(27)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:other_user) { create(:user) }
        let(:tournament) { create(:tournament, name: :foo) }
        let(:reasoning) { 'reasons' }

        before do
          sign_in user
        end

        it 'deletes when claimed by user' do
          claim = create(:tournament_claim, user:, tournament:, reasoning:)
          expect { delete admin_tournament_claim_path(claim) }.to change(TournamentClaim, :count).by(-1)
          expect(response).to redirect_to(admin_tournament_claims_path)
        end

        it 'fails to delete when claimed by other user' do
          claim = create(:tournament_claim, user: other_user, tournament:, reasoning:)
          expect { delete admin_tournament_claim_path(claim) }.not_to change(TournamentClaim, :count)
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
        end
      end
    end

    describe 'PATCH /approve' do
      it 'fails if not authenticated' do
        patch approve_admin_tournament_claim_path(27)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:tournament) { create(:tournament, name: :foo) }
        let(:reasoning) { 'reasons' }
        let(:claim) { create(:tournament_claim, user:, tournament:, reasoning:) }

        before do
          sign_in user
        end

        it 'fails when try to approve' do
          patch approve_admin_tournament_claim_path(claim), params: { approved: true }
          assert !claim.reload.approved?
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
        end

        it 'fails when try to unapprove' do
          claim.approve!
          patch approve_admin_tournament_claim_path(claim), params: { approved: false }
          assert claim.reload.approved?
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
        end
      end

      context 'when logged in as admin' do
        let(:user) { create(:user) }
        let(:tournament) { create(:tournament, name: :foo) }
        let(:reasoning) { 'reasons' }
        let(:claim) { create(:tournament_claim, user:, tournament:, reasoning:) }

        before do
          sign_in_admin
        end

        it 'approves' do
          patch approve_admin_tournament_claim_path(claim), params: { approved: true }
          assert claim.reload.approved?
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
        end

        it 'unapproves' do
          claim.approve!
          patch approve_admin_tournament_claim_path(claim), params: { approved: false }
          assert !claim.reload.approved?
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
        end

        it 'does not toggle' do
          claim.approve!
          patch approve_admin_tournament_claim_path(claim), params: { approved: true }
          assert claim.reload.approved?
          expect(response).to redirect_to(admin_tournament_claims_path)
          expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
        end
      end
    end
  end
end
