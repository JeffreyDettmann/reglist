class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.text :body
      t.references :user
      t.boolean :read, default: false
      t.boolean :from_admin, default: false
      t.boolean :requires_action, default: false
      t.timestamps
    end
  end
end
