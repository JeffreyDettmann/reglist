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
      create(:tournament, name: "Unapproved tournament #{time}", users: [user])
    end
    3.times do |time|
      new_tournament = create(:tournament, name: "Approved tournament #{time}", users: [user])
      new_tournament.tournament_claims.first.approve!
    end
    other_tournament = create(:tournament, name: 'Other tournament', users: [other_user])
    other_tournament.tournament_claims.first.approve!

    approved_tournaments = user.tournaments.approved
    expect(approved_tournaments.count).to eq 3
    approved_tournaments.each do |tournament|
      assert tournament.name.start_with?('Approved tournament')
    end
  end
end
