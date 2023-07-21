# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#many_link_name' do
    let(:name) { 'Great Name' }
    let(:info_url) { 'http://info.url' }
    let(:liquipedia_url) { 'https://liquipedia.net/ageofempires/GreatName' }
    it 'returns info url if info url' do
      tournament = create(:tournament, name:, info_url:, liquipedia_url:)
      expect(maybe_link_name(tournament)).to eq %(<a href="#{info_url}">#{tournament.name}</a>)
    end
    it 'returns liquipedia url if no info url' do
      tournament = create(:tournament, name:, liquipedia_url:)
      expect(maybe_link_name(tournament)).to eq %(<a href="#{liquipedia_url}">#{tournament.name}</a>)
    end
    it 'returns name if no info nor liquipedia url' do
      tournament = create(:tournament, name:)
      expect(maybe_link_name(tournament)).to eq name
    end
  end
end
