class CreateSellers < ActiveRecord::Migration
  def change
    create_table :sellers do |t|
      t.integer :seller_id
      t.string :seller_name

      t.timestamps null: false
    end
  end
end
