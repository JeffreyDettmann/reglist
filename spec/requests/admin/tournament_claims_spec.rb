# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::TournamentClaims', type: :request do
  describe 'GET /index' do
    it 'fails if not authenticated' do
      get admin_tournament_claims_path
      expect(response).to redirect_to(new_user_session_path)
    end
    context 'when logged in as admin' do
      let(:user) { create(:user) }
      let(:tournament_a) { create(:tournament, name: :foo) }
      let(:tournament_b) { create(:tournament, name: :bar) }
      before do
        sign_in_admin
      end

      it 'only returns claims with reasoning' do
        create(:tournament_claim, user:, tournament: tournament_a, approved: true)
        create(:tournament_claim, user:, tournament: tournament_b, approved: true, reasoning: :reasons)
        get admin_tournament_claims_path
        approved_claims = assigns(:approved_claims)
        unapproved_claims = assigns(:unapproved_claims)
        expect(approved_claims.size).to eq 1
        expect(unapproved_claims.size).to eq 0
        expect(approved_claims.first.tournament).to eq tournament_b
      end

      it 'separates claims by approval' do
        create(:tournament_claim, user:, tournament: tournament_a, approved: false, reasoning: :reasons)
        create(:tournament_claim, user:, tournament: tournament_b, approved: true, reasoning: :reasons)
        get admin_tournament_claims_path
        approved_claims = assigns(:approved_claims)
        unapproved_claims = assigns(:unapproved_claims)
        expect(approved_claims.size).to eq 1
        expect(unapproved_claims.size).to eq 1
        expect(approved_claims.first.tournament).to eq tournament_b
        expect(unapproved_claims.first.tournament).to eq tournament_a
      end
    end

    context 'when logged in as user' do
      let(:user) { @user }
      let(:other_user) { create(:user) }
      let(:tournament_a) { create(:tournament, name: :foo) }
      let(:tournament_b) { create(:tournament, name: :bar) }
      let(:tournament_c) { create(:tournament, name: :fiz) }
      let(:tournament_d) { create(:tournament, name: :biz) }
      before do
        sign_in_user
      end

      it 'only returns users claims' do
        create(:tournament_claim, user:, tournament: tournament_a, approved: false, reasoning: :reasons)
        create(:tournament_claim, user:, tournament: tournament_b, approved: true)
        create(:tournament_claim, user: other_user, tournament: tournament_c, approved: false, reasoning: :reasons)
        create(:tournament_claim, user: other_user, tournament: tournament_d, approved: true)
        get admin_tournament_claims_path
        approved_claims = assigns(:approved_claims)
        unapproved_claims = assigns(:unapproved_claims)
        expect(approved_claims.size).to eq 1
        expect(unapproved_claims.size).to eq 1
        expect(approved_claims.first.tournament).to eq tournament_b
        expect(unapproved_claims.first.tournament).to eq tournament_a
      end

      it 'separates claims by approval' do
        create(:tournament_claim, user:, tournament: tournament_a, approved: false, reasoning: :reasons)
        create(:tournament_claim, user:, tournament: tournament_b, approved: true)
        get admin_tournament_claims_path
        approved_claims = assigns(:approved_claims)
        unapproved_claims = assigns(:unapproved_claims)
        expect(approved_claims.size).to eq 1
        expect(unapproved_claims.size).to eq 1
        expect(approved_claims.first.tournament).to eq tournament_b
        expect(unapproved_claims.first.tournament).to eq tournament_a
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
      let(:user) { @user }
      let(:other_user) { create(:user, confirmed_at: 2.days.ago) }
      let(:claimable) { create(:tournament, name: 'Claimable') }
      let(:user_claim) { build(:tournament_claim, user:, reasoning: :reasons) }
      let(:unclaimable) { create(:tournament, name: 'Unclaimable', tournament_claims: [user_claim]) }
      let(:other_claim) { build(:tournament_claim, user: other_user, reasoning: :reasons) }
      let(:other_claimed) { create(:tournament, name: 'Other Claimed', tournament_claims: [other_claim]) }
      let(:reasoning) { 'Because I should own this' }
      let(:valid_params) { { tournament_claim: { reasoning: } } }
      let(:approved_params) { { tournament_claim: { approved: true, reasoning: :reasons } } }

      before do
        sign_in_user
      end

      it 'claims unclaimed tournament' do
        expect do
          post admin_tournament_tournament_claims_path(claimable), params: valid_params
        end.to change(TournamentClaim, :count).by(1)
        assert !TournamentClaim.last.approved?
      end

      it 'does not claim unclaimed tournament' do
        unclaimable
        expect do
          post admin_tournament_tournament_claims_path(unclaimable), params: valid_params
        end.to change(TournamentClaim, :count).by(0)
      end

      it 'claims tournament claimed by someone else' do
        other_claimed
        expect do
          post admin_tournament_tournament_claims_path(other_claimed), params: valid_params
        end.to change(TournamentClaim, :count).by(1)
        assert !TournamentClaim.last.approved?
      end

      it 'fails with blank reason' do
        expect do
          post admin_tournament_tournament_claims_path(claimable), params: { tournament_claim: { reasoning: '' } }
        end.to change(TournamentClaim, :count).by(0)
      end

      it 'does not approve claim even with approved params' do
        post admin_tournament_tournament_claims_path(claimable), params: approved_params
        assert !TournamentClaim.last.approved?
      end
    end
  end

  describe 'GET /edit' do
    it 'fails if not authenticated' do
      get edit_admin_tournament_claim_path(27)
      expect(response).to redirect_to(new_user_session_path)
    end
    context 'when logged in as user' do
      let(:user) { @user }
      let(:other_user) { create(:user) }
      let(:tournament) { create(:tournament, name: :foo) }
      before do
        sign_in_user
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
      let(:user) { @user }
      let(:other_user) { create(:user) }
      let(:tournament) { create(:tournament, name: :foo) }
      let(:reasoning) { 'updated reasons' }
      let(:valid_params) { { tournament_claim: { reasoning: } } }
      let(:approved_params) { { tournament_claim: { approved: true, reasoning: } } }
      before do
        sign_in_user
      end

      it 'allows update own claim' do
        claim = create(:tournament_claim, user:, tournament:, reasoning: :reasons)
        patch admin_tournament_claim_path(claim), params: valid_params
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(claim.reload.reasoning).to eq reasoning
      end

      it 'forbids update others claim' do
        claim = create(:tournament_claim, user: other_user, tournament:, reasoning: :reasons)
        patch admin_tournament_claim_path(claim), params: valid_params
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:alert]).to eq I18n.t(:not_authorized)
      end

      it 'does not update approval' do
        claim = create(:tournament_claim, user: other_user, tournament:, reasoning: :reasons)
        patch admin_tournament_claim_path(claim), params: approved_params
        assert !claim.reload.approved
      end
    end
  end

  describe 'DELETE /destroy' do
    it 'fails if not authenticated' do
      delete admin_tournament_claim_path(27)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in as user' do
      let(:user) { @user }
      let(:other_user) { create(:user) }
      let(:tournament) { create(:tournament, name: :foo) }
      let(:reasoning) { 'reasons' }
      before do
        sign_in_user
      end
      it 'deletes when claimed by user' do
        claim = create(:tournament_claim, user:, tournament:, reasoning:)
        expect { delete admin_tournament_claim_path(claim) }.to change(TournamentClaim, :count).by(-1)
        expect(response).to redirect_to(admin_tournament_claims_path)
      end
      it 'fails to delete when claimed by other user' do
        claim = create(:tournament_claim, user: other_user, tournament:, reasoning:)
        expect { delete admin_tournament_claim_path(claim) }.to change(TournamentClaim, :count).by 0
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
      let(:user) { @user }
      let(:tournament) { create(:tournament, name: :foo) }
      let(:reasoning) { 'reasons' }
      before do
        sign_in_user
        @claim = create(:tournament_claim, user:, tournament:, reasoning:)
      end

      it 'fails when try to approve' do
        patch approve_admin_tournament_claim_path(@claim), params: { approved: true }
        assert !@claim.reload.approved?
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:alert]).to eq I18n.t(:not_authorized)
      end

      it 'fails when try to unapprove' do
        @claim.approve!
        patch approve_admin_tournament_claim_path(@claim), params: { approved: false }
        assert @claim.reload.approved?
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:alert]).to eq I18n.t(:not_authorized)
      end
    end

    context 'when logged in as admin' do
      let(:user) { create(:user) }
      let(:tournament) { create(:tournament, name: :foo) }
      let(:reasoning) { 'reasons' }
      before do
        sign_in_admin
        @claim = create(:tournament_claim, user:, tournament:, reasoning:)
      end
      it 'approves' do
        patch approve_admin_tournament_claim_path(@claim), params: { approved: true }
        assert @claim.reload.approved?
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
      end
      it 'unapproves' do
        @claim.approve!
        patch approve_admin_tournament_claim_path(@claim), params: { approved: false }
        assert !@claim.reload.approved?
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
      end
      it 'does not toggle' do
        @claim.approve!
        patch approve_admin_tournament_claim_path(@claim), params: { approved: true }
        assert @claim.reload.approved?
        expect(response).to redirect_to(admin_tournament_claims_path)
        expect(flash[:notice]).to eq I18n.t(:thing_updated, name: :claim)
      end
    end
  end
end
