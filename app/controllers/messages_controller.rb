# frozen_string_literal: true

# Handles messages from unrestricted part of site
class MessagesController < ApplicationController
  before_action :new_tournament, only: %i[create new]

  def create
    @message.assign_attributes(message_params)
    if current_user
      if current_user.admin?
        @message.from_admin = true
      else
        @message.user = current_user
      end
      redirect = admin_messages_url
    else
      redirect = root_url
    end
    respond_to do |format|
      if @message.save
        format.html { redirect_to redirect, notice: 'Thank you for the comment!' }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def new_tournament
    @message = Message.new
  end

  def message_params
    params.require(:message).permit(:body, :user_id)
  end
end
