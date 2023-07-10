class AddInfoUrlToTournaments < ActiveRecord::Migration[7.0]
  def change
    add_column :tournaments, :info_url, :string
  end
end
