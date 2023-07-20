class AddFlagToTournament < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :flags, :string
  end
end
