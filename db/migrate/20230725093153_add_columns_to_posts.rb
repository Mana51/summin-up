class AddColumnsToPosts < ActiveRecord::Migration[6.1]
  def change
    rename_column :posts, :post, :content
    add_column :posts, :keyword, :string
    add_column :posts, :difficulty_id, :integer
    add_column :posts, :length_id, :integer
  end
end
