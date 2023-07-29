class AddIndexesToSupportUniquenessConstraints < ActiveRecord::Migration[7.0]
  def change
    add_index(:tournaments, :liquipedia_url, unique: true)
    remove_index(:tournaments, :name)
    add_index(:tournaments, :name, unique: true)
    add_index(:tournament_claims, [:tournament_id, :user_id], unique: true)
  end
end
