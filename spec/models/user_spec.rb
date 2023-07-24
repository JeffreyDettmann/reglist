# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  it 'basic user is not admin' do
    user = create(:user)
    assert !user.admin?
  end

  it 'can create admin' do
    user = create(:user, admin: true)
    assert user.admin?
  end

  it 'scopes approved tournaments' do
    user = create(:user)
    other_user = create(:user, email: 'other@example.com')
    create(:tournament, name: 'Unowned tournament')
    2.times do |time|
      claim = build(:tournament_claim, user:, reasoning: :reasons)
      create(:tournament, name: "Unapproved tournament #{time}", tournament_claims: [claim])
    end
    3.times do |time|
      claim = build(:tournament_claim, user:, approved: true)
      create(:tournament, name: "Approved tournament #{time}", tournament_claims: [claim])
    end
    claim = build(:tournament_claim, user: other_user, approved: true)
    create(:tournament, name: 'Other tournament', tournament_claims: [claim])

    approved_tournaments = user.tournaments.approved
    expect(approved_tournaments.count).to eq 3
    approved_tournaments.each do |tournament|
      assert tournament.name.start_with?('Approved tournament')
    end
  end
end
