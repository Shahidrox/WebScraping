class CreateMerchants < ActiveRecord::Migration
  def change
    create_table :merchants do |t|
      t.string :name
      t.string :granny_url
      t.string :website
      t.integer :ecodes_available
      t.float :max_savings
      t.float :average_savings
      t.integer :cards_available

      t.timestamps null: false
    end
  end
end
