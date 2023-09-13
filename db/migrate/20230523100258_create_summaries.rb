class CreateSummaries < ActiveRecord::Migration[6.1]
  def change
    create_table :summaries do |t|
      t.string :content
      t.integer :post_id
    end
  end
end
