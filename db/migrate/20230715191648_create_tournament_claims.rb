class CreateTournamentClaims < ActiveRecord::Migration[7.0]
  def change
    create_table :tournament_claims do |t|
      t.integer :user_id, index: true
      t.integer :tournament_id, index: true
      t.text :reasoning
      t.boolean :approved, default: false
      t.timestamps
    end
  end
end
