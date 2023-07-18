# frozen_string_literal: true

FactoryBot.define do
  sequence :email do |n|
    "email#{n}@example.com"
  end
  factory :user do
    email
    password { 'password' }
    password_confirmation { 'password' }
  end
end
