# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tournament do
  describe 'status' do
    it 'works with valid status' do
      tournament = build(:tournament, name: 'New')
      %i[submitted ignored pending].each do |status|
        tournament.status = status
        expect(tournament).to be_valid
      end
    end

    it 'publishes with if registration close' do
      tournament = build(:tournament, name: 'New', status: :published, registration_close: 1.day.from_now)
      expect(tournament).to be_valid
    end

    it 'does not work with invalid status' do
      expect { build(:tournament, name: 'New', status: :invalid_status) }.to raise_error(ArgumentError)
    end

    it 'does not publish if no registration close' do
      tournament = build(:tournament, name: 'New', status: :published)
      expect(tournament).not_to be_valid
    end
  end

  it 'guarantees uniqueness of liquipedia_url' do
    url = '/ageofempires/coolio'
    create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament = build(:tournament, name: 'New', liquipedia_url: url)
    expect(new_tournament).not_to be_valid
  end

  it 'guarantees uniqueness of liquipedia_url with leading or trailing space' do
    url = '/ageofempires/coolio'
    create(:tournament, name: 'Existing', liquipedia_url: url)
    ["#{url} ", " #{url}", " #{url} "].each do
      expect(build(:tournament, name: 'New', liquipedia_url: "#{url} ")).not_to be_valid
    end
  end

  it 'allows multiple null liquipedia_urls' do
    url = nil
    create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament = build(:tournament, name: 'New', liquipedia_url: "#{url} ")
    expect(new_tournament).to be_valid
  end

  it 'nulls empty liquipedia_urls' do
    url = ''
    new_tournament = create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament.reload
    expect(new_tournament.liquipedia_url).to be_nil
  end

  it 'checks validity of liquipedia_urls' do
    url = '/foo/bar'
    new_tournament = build(:tournament, name: 'New', liquipedia_url: "#{url} ")
    expect(new_tournament).not_to be_valid
  end

  it 'removes https protocol-domain for valid liquipedia_url' do
    url = 'https://liquipedia.net/ageofempires/Poseidon_Cup/2'
    new_tournament = create(:tournament, name: 'Existing', liquipedia_url: url)
    expect(new_tournament.liquipedia_url).to eq '/ageofempires/Poseidon_Cup/2'
  end

  it 'removes http protocol-domain for valid liquipedia_url' do
    url = 'http://liquipedia.net/ageofempires/Poseidon_Cup/2'
    new_tournament = create(:tournament, name: 'Existing', liquipedia_url: url)
    expect(new_tournament.liquipedia_url).to eq '/ageofempires/Poseidon_Cup/2'
  end

  it 'guarantees uniqueness of name' do
    name = 'Cool tournament'
    create(:tournament, name:)
    new_tournament = build(:tournament, name:)
    expect(new_tournament).not_to be_valid
    expect(new_tournament.name).to eq name
  end

  it 'guarantees uniqueness of name with trailing space' do
    name = 'Cool tournament'
    create(:tournament, name:)
    new_tournament = build(:tournament, name: "#{name} ")
    expect(new_tournament).not_to be_valid
  end

  it 'requires a name' do
    new_tournament = build(:tournament, name: '')
    expect(new_tournament).not_to be_valid
  end

  it 'removes leading and trailing space from name' do
    name = ' Cool tournament '
    new_tournament = create(:tournament, name:)
    new_tournament.reload
    expect(new_tournament.name).to eq 'Cool tournament'
  end

  describe 'owned_by' do
    let(:admin) { create(:user, admin: true) }
    let(:user) { create(:user, admin: false) }
    let(:tournament) { create(:tournament, name: 'Tournament') }

    it 'is owned by admin' do
      expect(tournament.owned_by(admin)).to be_truthy
    end

    it 'is owned by confirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: true)
      tournament.update(tournament_claims: [tournament_claim])
      expect(tournament.owned_by(user)).to be_truthy
    end

    it 'is not owned without user claim' do
      expect(tournament.owned_by(user)).to be_falsey
    end

    it 'is not owned with unconfirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: false, reasoning: :reasoning)
      tournament.update(tournament_claims: [tournament_claim])
      expect(tournament.owned_by(user)).to be_falsey
    end
  end

  describe 'wating_claim_by' do
    let(:user) { create(:user, admin: false) }
    let(:tournament) { create(:tournament, name: 'Tournament') }

    it 'is not waiting if confirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: true)
      tournament.update(tournament_claims: [tournament_claim])
      expect(tournament.waiting_claim_by(user)).to be_falsey
    end

    it 'is not waiting no user claim' do
      expect(tournament.waiting_claim_by(user)).to be_falsey
    end

    it 'is waiting with unapproved claim' do
      tournament_claim = build(:tournament_claim, user:, approved: false, reasoning: :reasoning)
      tournament.update(tournament_claims: [tournament_claim])
      expect(tournament.waiting_claim_by(user)).to be_truthy
    end
  end

  describe 'flags' do
    it 'adds new flags' do
      tournament = build(:tournament, plus_flags: %i[jim bob])
      expect(tournament.flags).not_to be_nil
      expect(tournament).to be_flag('jim')
      expect(tournament).to be_flag('bob')
    end

    it 'adds new flag' do
      tournament = build(:tournament, plus_flags: 'bob')
      expect(tournament.flags).not_to be_nil
      expect(tournament).to be_flag('bob')
    end

    it 'adds to existing flag' do
      tournament = build(:tournament, plus_flags: 'bob')
      tournament.plus_flags = 'jim'
      expect(tournament).to be_flag('jim')
      expect(tournament).to be_flag('bob')
      expect(tournament).not_to be_flag('tim')
    end

    it 'removes correct flag' do
      tournament = build(:tournament, plus_flags: %i[jim bob tim])
      tournament.minus_flags('tim')
      expect(tournament).to be_flag('jim')
      expect(tournament).to be_flag('bob')
      expect(tournament).not_to be_flag('tim')
    end

    it 'removes correct flags' do
      tournament = build(:tournament, plus_flags: %i[jim bob tim])
      tournament.minus_flags(%w[jim tim])
      expect(tournament).not_to be_flag('jim')
      expect(tournament).to be_flag('bob')
      expect(tournament).not_to be_flag('tim')
    end
  end
end
