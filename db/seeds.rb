# frozen_string_literal: true

# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

admin = User.new(email: 'admin@example.com', password: 'password', password_confirmation: 'password', admin: true)
admin.skip_confirmation!
admin.save!
