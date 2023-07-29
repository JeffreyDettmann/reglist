# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentClaim do
  let(:user) { create(:user) }
  let(:claim) { build(:tournament_claim, user:, reasoning: :reasons) }
  let(:second_claim) { build(:tournament_claim, user:, reasoning: :reasons) }

  it 'approves' do
    create(:tournament, tournament_claims: [claim], name: 'foo')
    assert !claim.reload.approved
    claim.approve!
    claim.reload
    expect(claim).to be_approved
  end

  it 'does not create duplicate claim' do
    tournament = create(:tournament, tournament_claims: [claim], name: 'foo')
    expect do
      create(:tournament_claim, user:, tournament:)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'can create claims for multiple tournaments' do
    create(:tournament, tournament_claims: [claim], name: 'foo')
    expect do
      create(:tournament, tournament_claims: [second_claim], name: 'bar')
    end.to change(described_class, :count).by 1
  end
end
