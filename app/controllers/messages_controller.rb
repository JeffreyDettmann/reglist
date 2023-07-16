# frozen_string_literal: true

# Handles messages from unrestricted part of site
class MessagesController < ApplicationController
  def new
    @message = Message.new
  end

  def create
    @message = Message.new
    @message.assign_attributes(message_params)
    @message.user = current_user
    respond_to do |format|
      if @message.save
        format.html { redirect_to root_url, notice: 'Thank you for the comment!' }
        format.json { render :show, status: :created, location: @message }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @message.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def message_params
    params.require(:message).permit(:body)
  end
end
