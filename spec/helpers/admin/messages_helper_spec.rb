# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MessagesHelper, type: :helper do
  describe 'message alignment' do
    let(:admin) { create(:user, admin: true) }
    let(:user) { create(:user, admin: false) }
    let(:from_admin) { create(:message, body: 'from admin', from_admin: true, user:) }
    let(:from_user) { create(:message, body: 'from user', from_admin: false, user:) }
    context 'current user is admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      it 'returns correct alignment' do
        expect(helper.message_alignment(from_admin)).to eq 'right'
        expect(helper.message_alignment(from_user)).to eq 'left'
      end
    end
    context 'current user is not admin' do
      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it 'returns correct alignment' do
        expect(helper.message_alignment(from_admin)).to eq 'left'
        expect(helper.message_alignment(from_user)).to eq 'right'
      end
    end
  end

  describe 'test unread' do
    it 'when message unread' do
      message = create(:message, body: 'Unread')
      message.reload
      assert helper.unread(message)
    end
    it 'when message read but was unread' do
      message = create(:message, body: 'Unread')
      message.reload
      message.update(read: true)
      assert message.read
      assert helper.unread(message)
    end
    it 'when message read but was updated' do
      message = create(:message, body: 'Read', read: true)
      message.reload
      message.update(body: 'Updated')
      assert message.read
      assert !helper.unread(message)
    end
    it 'when message read but not updated' do
      message = create(:message, body: 'Read', read: true)
      message.reload
      assert message.read
      assert !helper.unread(message)
    end
    it 'when message updated then reloaded' do
      message = create(:message, body: 'Unread')
      message.update(read: true)
      message.reload
      assert message.read
      assert !helper.unread(message)
    end
  end
end
