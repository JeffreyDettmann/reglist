class CreateTournaments < ActiveRecord::Migration[7.0]
  def change
    create_table :tournaments do |t|
      t.string :name, index: true
      t.string :liquipedia_url
      t.string :rules_url
      t.string :registration_url
      t.string :format
      t.string :game
      t.string :tier
      t.string :prize_pool
      t.text :restrictions
      t.text :notes
      t.string :organizers
      t.string :state
      t.date :registration_close, index: true
      t.date :start_date, index: true
      t.date :end_date
      t.timestamps
    end
  end
end
