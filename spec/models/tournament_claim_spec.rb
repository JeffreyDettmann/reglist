# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentClaim, type: :model do
  before do
    @user = create(:user, admin: false)
  end

  it 'approves' do
    claim = build(:tournament_claim, user: @user, reasoning: :reasons)
    create(:tournament, tournament_claims: [claim], name: 'foo')
    assert !claim.reload.approved
    claim.approve!
    claim.reload
    assert claim.approved
  end

  it 'does not create duplicate claim' do
    claim = build(:tournament_claim, user: @user, reasoning: :reasons)
    tournament = create(:tournament, tournament_claims: [claim], name: 'foo')
    expect do
      create(:tournament_claim, user: @user, tournament:)
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'can create claims for multiple tournaments' do
    claim = build(:tournament_claim, user: @user, reasoning: :reasons)
    expect do
      create(:tournament, tournament_claims: [claim], name: 'foo')
    end.to change(TournamentClaim, :count).by 1

    claim = build(:tournament_claim, user: @user, reasoning: :reasons)
    expect do
      create(:tournament, tournament_claims: [claim], name: 'bar')
    end.to change(TournamentClaim, :count).by 1
  end
end
