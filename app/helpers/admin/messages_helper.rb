# frozen_string_literal: true

# helpers for admin views
module Admin
  # helpers for message views
  module MessagesHelper
    def message_alignment(message)
      if current_user.admin?
        if message.from_admin?
          'right'
        else
          'left'
        end
      elsif message.from_admin?
        'left'
      else
        'right'
      end
    end

    def unread(message)
      !message.read || message.read_before_last_save == false
    end

    def conversation_partner(message)
      if current_user.admin?
        message.user&.email || 'anonymous'
      else
        'Site Admin'
      end
    end

    def requires_action(message)
      if current_user.admin?
        button_text = message.requires_action? ? '&#x2757;' : '&#x2705;'
        button_to(raw(button_text), toggle_requires_action_admin_message_path(message), method: :patch)
      else
        '&nbsp;'
      end
    end
  end
end
