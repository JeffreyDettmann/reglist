# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tournament, type: :model do
  describe 'status' do
    it 'works with valid status' do
      tournament = build(:tournament, name: 'New')
      %i[submitted ignored pending].each do |status|
        tournament.status = status
        assert tournament.valid?
      end
      tournament.registration_close = 1.day.ago
      tournament.status = :published
      assert tournament.valid?
    end

    it 'does not work with invalid status' do
      expect { build(:tournament, name: 'New', status: :invalid_status) }.to raise_error(ArgumentError)
    end

    it 'does not publish if no registration close' do
      tournament = build(:tournament, name: 'New', status: :published)
      assert !tournament.valid?
    end
  end

  it 'guarantees uniqueness of liquipedia_url' do
    url = '/ageofempires/coolio'
    create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament = build(:tournament, name: 'New', liquipedia_url: url)
    assert !new_tournament.valid?
  end

  it 'guarantees uniqueness of liquipedia_url with leading or trailing space' do
    url = '/ageofempires/coolio'
    create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament = build(:tournament, name: 'New', liquipedia_url: "#{url} ")
    assert !new_tournament.valid?
    new_tournament.liquipedia_url = " #{url}"
    assert !new_tournament.valid?
  end

  it 'allows multiple null liquipedia_urls' do
    url = nil
    create(:tournament, name: 'Existing', liquipedia_url: url)
    new_tournament = build(:tournament, name: 'New', liquipedia_url: "#{url} ")
    assert new_tournament.valid?
    new_tournament.save!
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
    assert !new_tournament.valid?
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
    assert !new_tournament.valid?
    assert new_tournament.name == name
  end

  it 'guarantees uniqueness of name with trailing space' do
    name = 'Cool tournament'
    create(:tournament, name:)
    new_tournament = build(:tournament, name: "#{name} ")
    assert !new_tournament.valid?
  end

  it 'requires a name' do
    new_tournament = build(:tournament, name: '')
    assert !new_tournament.valid?
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
      assert tournament.owned_by(admin)
    end

    it 'is owned by confirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: true)
      tournament.update(tournament_claims: [tournament_claim])
      assert tournament.owned_by(user)
    end

    it 'is not owned without user claim' do
      assert !tournament.owned_by(user)
    end

    it 'is not owned with unconfirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: false, reasoning: :reasoning)
      tournament.update(tournament_claims: [tournament_claim])
      assert !tournament.owned_by(user)
    end
  end

  describe 'wating_claim_by' do
    let(:user) { create(:user, admin: false) }
    let(:tournament) { create(:tournament, name: 'Tournament') }

    it 'is not waiting if confirmed user claim' do
      tournament_claim = build(:tournament_claim, user:, approved: true)
      tournament.update(tournament_claims: [tournament_claim])
      assert !tournament.waiting_claim_by(user)
    end

    it 'is not waiting no user claim' do
      assert !tournament.waiting_claim_by(user)
    end

    it 'is waiting with unapproved claim' do
      tournament_claim = build(:tournament_claim, user:, approved: false, reasoning: :reasoning)
      tournament.update(tournament_claims: [tournament_claim])
      assert tournament.waiting_claim_by(user)
    end
  end

  describe 'flags' do
    it 'adds new flags' do
      tournament = build(:tournament, plus_flags: %i[jim bob])
      expect(tournament.flags).to_not be_nil
      assert tournament.flag?('jim')
      assert tournament.flag?('bob')
    end

    it 'adds new flag' do
      tournament = build(:tournament, plus_flags: 'bob')
      expect(tournament.flags).to_not be_nil
      assert tournament.flag?('bob')
    end

    it 'adds to existing flag' do
      tournament = build(:tournament, plus_flags: 'bob')
      tournament.plus_flags = 'jim'
      assert tournament.flag?('jim')
      assert tournament.flag?('bob')
      assert !tournament.flag?('tim')
    end

    it 'removes correct flag' do
      tournament = build(:tournament, plus_flags: %i[jim bob tim])
      tournament.minus_flags('tim')
      assert tournament.flag?('jim')
      assert tournament.flag?('bob')
      assert !tournament.flag?('tim')
    end

    it 'removes correct flags' do
      tournament = build(:tournament, plus_flags: %i[jim bob tim])
      tournament.minus_flags(%w[jim tim])
      assert !tournament.flag?('jim')
      assert tournament.flag?('bob')
      assert !tournament.flag?('tim')
    end
  end
end
