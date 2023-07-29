# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MessagesHelper do
  describe 'add links' do
    it 'ignores messages that do not match replacement pattern' do
      body = 'Does not match pattern 27'
      message = build(:message, body:)
      expect(add_links(message)).to eq body
    end

    it 'Turns auto-generated request into link' do
      body = 'Please publish My Cool Tournament'
      new_body = 'Please publish <a href="/admin/tournaments?status=pending">My Cool Tournament</a>'
      message = build(:message, body:)
      expect(add_links(message)).to eq new_body
    end
  end

  describe 'message alignment' do
    let(:admin) { create(:user, admin: true) }
    let(:user) { create(:user, admin: false) }
    let(:from_admin) { create(:message, body: 'from admin', from_admin: true, user:) }
    let(:from_user) { create(:message, body: 'from user', from_admin: false, user:) }

    context 'when current user is admin' do
      before do
        allow(controller).to receive(:current_user).and_return(admin)
      end

      it 'returns correct alignment' do
        expect(helper.message_alignment(from_admin)).to eq 'right'
        expect(helper.message_alignment(from_user)).to eq 'left'
      end
    end

    context 'when current user is not admin' do
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
      expect(helper.unread(message)).to be_truthy
    end

    it 'when message read but was unread' do
      message = create(:message, body: 'Unread')
      message.reload
      message.update(read: true)
      assert message.read
      expect(helper.unread(message)).to be_truthy
    end

    it 'when message read but was updated' do
      message = create(:message, body: 'Read', read: true)
      message.reload
      message.update(body: 'Updated')
      assert message.read
      expect(helper.unread(message)).to be_falsey
    end

    it 'when message read but not updated' do
      message = create(:message, body: 'Read', read: true)
      message.reload
      assert message.read
      expect(helper.unread(message)).to be_falsey
    end

    it 'when message updated then reloaded' do
      message = create(:message, body: 'Unread')
      message.update(read: true)
      message.reload
      assert message.read
      expect(helper.unread(message)).to be_falsey
    end
  end
end
