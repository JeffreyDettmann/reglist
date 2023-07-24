# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Messages', type: :request do
  describe 'GET /index' do
    it 'fails if not authenticated' do
      get admin_messages_path
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'logged in as admin' do
      before do
        sign_in_admin
        load_messages
      end

      it 'returns list of users if no user id param' do
        get admin_messages_path
        user_messages = assigns(:user_messages)
        expect(user_messages.size).to eq 4
        user_messages.each do |email, counts|
          case email
          when nil
            expect(counts[:read]).to eq 3
            expect(counts[:unread]).to eq 2
          when 'unread_user@example.com'
            expect(counts[:read]).to eq 0
            expect(counts[:unread]).to eq 1
          when 'read_user@example.com'
            expect(counts[:read]).to eq 2
            expect(counts[:unread]).to eq 0
          when 'both@example.com'
            expect(counts[:read]).to eq 2
            expect(counts[:unread]).to eq 1
            expect(counts[:requires_action]).to eq 2
          else
            raise "Unexpected email #{email}"
          end
        end
      end

      it 'returns messages if user param sent' do
        get admin_messages_path, params: { user: 'both@example.com' }
        messages = assigns(:messages)
        expect(messages.size).to eq 3
        counter = {}
        counter.default = 0
        messages.each do |message|
          counter[message.body] += 1
        end
        expect(counter['Unread message']).to eq 1
        expect(counter['Read message']).to eq 2
      end

      it 'returns anonymous if user param is "anonymous"' do
        get admin_messages_path, params: { user: 'anonymous' }
        messages = assigns(:messages)
        expect(messages.size).to eq 5
        counter = {}
        counter.default = 0
        messages.each do |message|
          counter[message.body] += 1
        end
        expect(counter['Unread Anonymous Message']).to eq 2
        expect(counter['Read Anonymous Message']).to eq 3
      end

      it 'marks all messages as read, while maintaining read_before_last_save' do
        get admin_messages_path, params: { user: 'anonymous' }
        expect(assigns(:messages).size).to eq 5
        assigns(:messages).each do |message|
          if message.body == 'Unread Anonymous Message'
            expect(message.read_before_last_save).to be false
          else
            expect(message.read_before_last_save).to be true
          end
          expect(message.read).to be true
        end
      end

      def load_messages
        2.times do |index|
          create(:message, body: 'Unread Anonymous Message', created_at: index.days.ago)
        end
        3.times do |index|
          create(:message, body: 'Read Anonymous Message', created_at: index.days.ago, read: true)
        end
        unread_user = create(:user, email: 'unread_user@example.com')
        create(:message, body: 'Unread user message', user: unread_user)
        read_user = create(:user, email: 'read_user@example.com')
        2.times do
          create(:message, body: 'Read user message', user: read_user, read: true)
        end
        both_user = create(:user, email: 'both@example.com')
        create(:message, body: 'Unread message', user: both_user)
        create(:message, body: 'Read message', user: both_user, read: true, requires_action: true)
        create(:message, body: 'Read message', user: both_user, read: true, requires_action: true)
      end
    end

    context 'logged in as user' do
      before do
        sign_in_user
        load_messages(@user)
      end

      it 'returns messages in order' do
        get admin_messages_path
        messages = assigns(:messages)
        expect(messages.size).to eq 4
        messages.each_with_index do |message, index|
          case index
          when 0
            expect(message.body).to eq 'Read message to admin'
            expect(message.read).to be true
          when 1
            expect(message.body).to eq 'Read message from admin'
            expect(message.read).to be true
            expect(message.from_admin).to be true
          when 2
            expect(message.body).to eq 'Unread message to admin'
            expect(message.read).to be false
          when 3
            expect(message.body).to eq 'Unread message from admin'
            expect(message.from_admin).to be true
            expect(message.read).to be true
            expect(message.read_before_last_save).to be false
          end
        end
      end

      def load_messages(user)
        create(:message, body: 'Read message to admin', read: true, created_at: 5.days.ago, user:)
        create(:message, body: 'Read message from admin', from_admin: true, read: true, created_at: 4.days.ago, user:)
        create(:message, body: 'Unread message to admin', created_at: 3.days.ago, user:)
        create(:message, body: 'Unread message from admin', from_admin: true, created_at: 2.days.ago, user:)
      end
    end
  end

  describe 'PATCH /:id/toggle_requires_action' do
    let(:user) { create(:user) }
    let(:requires_action) { create(:message, body: 'Requires action', requires_action: true, user:) }
    let(:not_requires_action) { create(:message, body: 'Does not require action', requires_action: false) }
    it 'fails if not authenticated' do
      patch toggle_requires_action_admin_message_path(requires_action)
      expect(response).to redirect_to(new_user_session_path)
    end

    context 'logged in as admin' do
      before do
        sign_in_admin
      end

      it 'sets requires_action to false when message requires action' do
        patch toggle_requires_action_admin_message_path(requires_action)
        expect(response).to redirect_to(admin_messages_url(user: user.email))
        assert !requires_action.reload.requires_action
      end

      it 'sets requires_action to true when message does not  require action' do
        patch toggle_requires_action_admin_message_path(not_requires_action)
        expect(response).to redirect_to(admin_messages_url(user: 'anonymous'))
        assert not_requires_action.reload.requires_action
      end
    end

    context 'logged in as user' do
      before do
        sign_in_user
      end

      it 'fails' do
        patch toggle_requires_action_admin_message_path(requires_action)
        expect(response).to redirect_to(admin_messages_url)
        expect(flash[:alert]).to eq I18n.t(:not_authorized)
      end
    end
  end
end
