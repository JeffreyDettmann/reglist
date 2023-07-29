# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  it 'basic user is not admin' do
    expect(user).not_to be_admin
  end

  it 'can create admin' do
    admin = create(:user, admin: true)
    expect(admin).to be_admin
  end

  it 'scopes approved tournaments' do
    load_tournaments
    create(:tournament, name: 'Unowned tournament')
    approved_tournaments = user.tournaments.approved
    expect(approved_tournaments.count).to eq 3
    expect(approved_tournaments.map(&:name)).to all start_with('Approved tournament')
  end

  def load_tournaments
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
  end
end
