class AddRequestPublicationToTournament < ActiveRecord::Migration[7.0]
  def change
    add_reference :tournaments, :message, foreign_key: true, optional: true
  end
end
