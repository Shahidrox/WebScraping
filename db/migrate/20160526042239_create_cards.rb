class CreateCards < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.references :card_detail, index: true, foreign_key: true
      t.integer :rank
      t.string :merchant
      t.string :card_type
      t.integer :quantity
      t.float :value
      t.float :discount
      t.string :seller

      t.timestamps null: false
    end
  end
end
