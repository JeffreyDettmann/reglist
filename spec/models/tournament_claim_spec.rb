# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TournamentClaim, type: :model do
  before do
    @user = create(:user, admin: false)
  end

  it 'automagically exists when tournament created with user' do
    expect do
      create(:tournament, users: [@user], name: 'foo')
    end.to change(TournamentClaim, :count).by(1)
  end

  it 'approves' do
    tournament = create(:tournament, users: [@user], name: 'foo')
    claim = tournament.tournament_claims.first
    assert !claim.approved
    claim.approve!
    claim.reload
    assert claim.approved
  end
end
