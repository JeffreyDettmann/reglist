# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::TournamentClaims', type: :request do
  describe 'GET /new' do
    let(:tournament) { create(:tournament, name: :foo) }
    it 'fails if not authenticated' do
      get new_admin_tournament_tournament_claim_path(tournament)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'when logged in' do
      before do
        user = create(:user, confirmed_at: 2.days.ago)
        sign_in user
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
      let(:user) { create(:user, confirmed_at: 2.days.ago) }
      let(:other_user) { create(:user, confirmed_at: 2.days.ago) }
      let(:claimable) { create(:tournament, name: 'Claimable') }
      let(:user_claim) { build(:tournament_claim, user:, reasoning: :reasons) }
      let(:unclaimable) { create(:tournament, name: 'Unclaimable', tournament_claims: [user_claim]) }
      let(:other_claim) { build(:tournament_claim, user: other_user, reasoning: :reasons) }
      let(:other_claimed) { create(:tournament, name: 'Other Claimed', tournament_claims: [other_claim]) }
      let(:reasoning) { 'Because I should own this' }
      let(:valid_params) { { tournament_claim: { reasoning: } } }

      before do
        sign_in user
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
    end
  end
end
