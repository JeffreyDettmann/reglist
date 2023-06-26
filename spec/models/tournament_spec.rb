# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tournament, type: :model do
  it 'works with valid status' do
    %i[submitted ignored pending published].each do |status|
      tournament = build(:tournament, name: 'New', status:)
      assert tournament.valid?
    end
  end

  it 'does not work with invalid status' do
    expect { build(:tournament, name: 'New', status: :invalid_status) }.to raise_error(ArgumentError)
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
end
