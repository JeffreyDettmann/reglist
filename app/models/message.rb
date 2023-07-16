# frozen_string_literal: true

# Individual communication between admins and user
class Message < ApplicationRecord
  belongs_to :user, optional: true
  validates_presence_of :body

  def sender
    if user.nil?
      'anonymous'
    elsif user.admin?
      'admin'
    else
      user.email
    end
  end
end
