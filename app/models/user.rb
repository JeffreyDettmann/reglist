# frozen_string_literal: true

# Someone who can manage tournaments
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :trackable, :confirmable,
         :recoverable, :rememberable, :validatable
end