class AddCategoryToBands < ActiveRecord::Migration[8.1]
  def change
    add_reference :bands, :category, null: true, foreign_key: true
  end
end
