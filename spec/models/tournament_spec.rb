# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tournament, type: :model do
  it 'works with valid status' do
    %i[submitted ignored published].each do |status|
      tournament = build(:tournament, status:)
      assert tournament.valid?
    end
  end

  it 'does not work with invalid status' do
    expect { build(:tournament, status: :invalid_status) }.to raise_error(ArgumentError)
  end
end
