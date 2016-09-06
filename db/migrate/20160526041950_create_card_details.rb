class CreateCardDetails < ActiveRecord::Migration
  def change
    create_table :card_details do |t|
      t.string :day

      t.timestamps null: false
    end
  end
end
