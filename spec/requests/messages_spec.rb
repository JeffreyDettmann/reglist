# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Messages', type: :request do
  describe 'GET /new' do
    it 'does not fail' do
      get new_messages_path
      expect(response).to be_successful
    end
  end

  describe 'POST /create' do
    context 'anonymous user' do
      it 'fails when no body' do
        post messages_path, params: { message: { body: '' } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'fails when body just whitespace' do
        post messages_path, params: { message: { body: "   \n\t   " } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'creates message on success' do
        body = 'You are doing a great job!'
        expect do
          post messages_path, params: { message: { body: } }
        end.to change(Message, :count).by(1)
        expect(Message.last.body).to eq body
        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to_not be_nil
      end

      it 'does not require action' do
        body = 'You are doing a great job!'
        expect do
          post messages_path, params: { message: { body: } }
        end.to change(Message, :count).by(1)
        assert !Message.last.requires_action
      end

      it 'does not come from admin' do
        body = 'You are doing a great job!'
        expect do
          post messages_path, params: { message: { body: } }
        end.to change(Message, :count).by(1)
        assert !Message.last.from_admin
      end

      it 'does not add user to message' do
        body = 'You are doing a great job!'
        expect do
          post messages_path, params: { message: { body: } }
        end.to change(Message, :count).by(1)
        expect(Message.last.user).to be_nil
      end
    end

    context 'logged in user' do
      before do
        @user = create(:user, confirmed_at: Time.now)
        sign_in @user
      end

      it 'adds user to message' do
        body = 'You are doing a great job!'
        expect do
          post messages_path, params: { message: { body: } }
        end.to change(Message, :count).by(1)
        expect(Message.last.user).to eq @user
      end

      it 'redirects to admin messages' do
        body = 'You are doing a great job!'
        post messages_path, params: { message: { body: } }
        expect(response).to redirect_to(admin_messages_url)
      end
    end

    context 'admin user' do
      before do
        @user = create(:user, confirmed_at: Time.now)
        admin = create(:user, admin: true, confirmed_at: Time.now)
        sign_in admin
      end

      it 'adds user to message' do
        body = 'Thanks for the compliment!'
        expect do
          post messages_path, params: { message: { user_id: @user.id, body: } }
        end.to change(Message, :count).by(1)
        message = Message.last
        expect(message.user).to eq @user
        assert message.from_admin?
      end

      it 'redirects to admin messages' do
        body = 'Thanks for the compliment!'
        post messages_path, params: { message: { body: } }
        expect(response).to redirect_to(admin_messages_url)
      end
    end
  end
end
