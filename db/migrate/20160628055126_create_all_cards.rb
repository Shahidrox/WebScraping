class CreateAllCards < ActiveRecord::Migration
  def change
    create_table :all_cards do |t|
      t.integer :rank
      t.string :merchant
      t.string :card_type
      t.integer :quantity
      t.float :value
      t.float :discount
      t.string :seller
      t.float :one_and_one
      t.float :one_and_gcs

      t.timestamps null: false
    end
  end
end
