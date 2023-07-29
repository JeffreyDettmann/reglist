# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Messages' do
  context 'without accept cookie' do
    it 'redirects home with message' do
      get admin_messages_path
      expect(response).to redirect_to(root_url(pointless: true))
    end
  end

  context 'with accept cookie' do
    before do
      get compliance_dmca_path, params: { accept_cookies: 'true' }
    end

    describe 'GET /index' do
      it 'fails if not authenticated' do
        get admin_messages_path
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as admin' do
        let(:expected_messages) do
          { nil => { read: 3, unread: 2, requires_action: 0 },
            'unread_user@example.com' => { read: 0, unread: 1, requires_action: 0 },
            'read_user@example.com' => { read: 2, unread: 0, requires_action: 0 },
            'both@example.com' => { read: 2, unread: 1, requires_action: 2 } }
        end

        before do
          sign_in_admin
          load_messages
        end

        it 'returns list of users if no user id param' do
          get admin_messages_path
          expect(assigns(:user_messages).size).to eq 4
          assigns(:user_messages).each do |email, counts|
            expect(expected_messages[email]).to eq counts
          end
        end

        it 'returns messages if user param sent' do
          get admin_messages_path, params: { user: 'both@example.com' }
          messages = assigns(:messages)
          expect(messages.size).to eq 3
          message_bodies = ['Read message', 'Read message', 'Unread message']
          expect(messages.map(&:body).sort).to eq message_bodies
        end

        it 'returns anonymous if user param is "anonymous"' do
          get admin_messages_path, params: { user: 'anonymous' }
          expect(assigns(:messages).size).to eq 5
          message_bodies = ['Read Anonymous Message', 'Read Anonymous Message', 'Read Anonymous Message',
                            'Unread Anonymous Message', 'Unread Anonymous Message']
          expect(assigns(:messages).map(&:body).sort).to eq message_bodies
        end

        it 'marks all messages as read, while maintaining read_before_last_save' do
          get admin_messages_path, params: { user: 'anonymous' }
          assigns(:messages).each do |message|
            expect(message.read_before_last_save).to eq(message.body != 'Unread Anonymous Message')
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
          create_list(:message, 2, body: 'Read user message', user: read_user, read: true)
          both_user = create(:user, email: 'both@example.com')
          create(:message, body: 'Unread message', user: both_user)
          create(:message, body: 'Read message', user: both_user, read: true, requires_action: true)
          create(:message, body: 'Read message', user: both_user, read: true, requires_action: true)
        end
      end

      context 'when logged in as user' do
        let(:user) { create(:user, admin: false, confirmed_at: 2.days.ago) }
        let(:expected_messages) do
          ['Read message to admin',
           'Read message from admin',
           'Unread message to admin',
           'Unread message from admin']
        end

        before do
          sign_in user
          load_messages(user)
        end

        it 'returns messages in order' do
          get admin_messages_path
          messages = assigns(:messages)
          expect(messages.map(&:body)).to eq expected_messages
          expect(messages.map(&:from_admin)).to eq [false, true, false, true]
        end

        def load_messages(user)
          create(:message, body: 'Read message to admin', read: true, created_at: 5.days.ago, user:)
          create(:message, body: 'Read message from admin', from_admin: true, read: true, created_at: 4.days.ago, user:)
          create(:message, body: 'Unread message to admin', created_at: 3.days.ago, user:)
          create(:message, body: 'Unread message from admin', from_admin: true, created_at: 2.days.ago, user:)
        end
      end
    end

    describe 'DELETE /:id' do
      let(:user) { create(:user) }
      let(:unwanted_message) { create(:message, body: 'Not wanted', user:) }
      let(:anonymous_unwanted_message) { create(:message, body: 'Not wanted from anonymous') }

      it 'fails if not authenticated' do
        unwanted_message
        expect do
          delete admin_message_path(unwanted_message)
        end.not_to change(Message, :count)
        expect(response).to redirect_to(new_user_session_path)
      end

      context 'when logged in as admin' do
        before do
          sign_in_admin
          unwanted_message
          anonymous_unwanted_message
        end

        it 'deletes and redirects to user messages' do
          expect do
            delete admin_message_path(unwanted_message)
          end.to change(Message, :count).by(-1)
          assert !Message.exists?(id: unwanted_message)
          expect(response).to redirect_to(admin_messages_url(user: user.email))
        end

        it 'deletes and redirects to anonymous' do
          expect do
            delete admin_message_path(anonymous_unwanted_message)
          end.to change(Message, :count).by(-1)
          assert !Message.exists?(id: anonymous_unwanted_message)
          expect(response).to redirect_to(admin_messages_url(user: 'anonymous'))
        end
      end

      context 'when logged in as user' do
        before do
          sign_in_user
          unwanted_message
        end

        it 'fails' do
          expect do
            delete admin_message_path(unwanted_message)
          end.not_to change(Message, :count)
          assert Message.exists?(id: unwanted_message)
          expect(flash[:alert]).to eq I18n.t(:not_authorized)
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

      context 'when logged in as admin' do
        before do
          sign_in_admin
        end

        it 'sets requires_action to false when message requires action' do
          patch toggle_requires_action_admin_message_path(requires_action)
          expect(response).to redirect_to(admin_messages_url(user: user.email))
          assert !requires_action.reload.requires_action
        end

        it 'sets requires_action to true when message does not require action' do
          patch toggle_requires_action_admin_message_path(not_requires_action)
          expect(response).to redirect_to(admin_messages_url(user: 'anonymous'))
          assert not_requires_action.reload.requires_action
        end
      end

      context 'when logged in as user' do
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
end
