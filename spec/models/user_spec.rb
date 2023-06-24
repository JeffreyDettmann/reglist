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
end
