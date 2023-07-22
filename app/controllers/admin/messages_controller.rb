# frozen_string_literal: true

# Administrative controllers
module Admin
  # Manages messages received by user
  class MessagesController < AdminController
    def index
      @user_messages = {}
      @messages = []
      if current_user.admin?
        assign_admin_messages
        @messages.each { |m| m.update_attribute(:read, true) unless m.from_admin? }
      else
        @messages = Message.where(user: current_user).order(:created_at)
        @messages.each { |m| m.update_attribute(:read, true) if m.from_admin? }
      end
      @message = Message.new(user_id: @messages.first&.user_id)
    end

    def toggle_requires_action
      if current_user.admin?
        message = Message.find(params[:id])
        message.update(requires_action: !message.requires_action)
        redirect_to admin_messages_url(user: message.user&.email || 'anonymous')
      else
        redirect_to admin_messages_url,
                    alert: t(:not_authorized)
      end
    end

    private

    def assign_admin_messages
      if params[:user] == 'anonymous'
        @messages = Message.where(user: nil).order(created_at: :desc)
      elsif params[:user]
        @messages = Message.joins(:user).where('users.email = ?', params[:user]).order(:created_at)
      else
        assign_user_messages
      end
    end

    def assign_user_messages
      Message.joins('LEFT JOIN users ON user_id = users.id')
             .where(from_admin: false)
             .group('users.email', :read, :requires_action).count.each do |user_message|
        email, read, requires_action = user_message[0]
        status = read ? :read : :unread
        count = user_message[1]
        @user_messages[email] ||= { read: 0, unread: 0, requires_action: 0 }
        @user_messages[email][status] += count
        @user_messages[email][:requires_action] += count if requires_action
      end
    end
  end
end
