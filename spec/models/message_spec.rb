# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Message do
  it 'does not require user' do
    expect { create(:message, body: 'some body') }.not_to raise_exception
  end

  it 'requires body' do
    message = build(:message)
    assert !message.valid?
    expect(message.errors).to include :body
  end

  describe 'sender' do
    it 'is "admin" if user admin' do
      user = create(:user, admin: true)
      message = build(:message, user:)
      expect(message.sender).to eq 'admin'
    end

    it 'is "anonymous" if no user' do
      message = build(:message)
      expect(message.sender).to eq 'anonymous'
    end

    it 'is email if non-admin user' do
      email = 'messenger@example.com'
      user = create(:user, admin: false, email:)
      message = build(:message, user:)
      expect(message.sender).to eq email
    end
  end
end
