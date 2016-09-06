class AddDiffToCards < ActiveRecord::Migration
  def change
    add_column :cards, :one_and_one, :float
    add_column :cards, :one_and_gcs, :float
  end
end
