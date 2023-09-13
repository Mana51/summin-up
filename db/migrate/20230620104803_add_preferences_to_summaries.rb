class AddPreferencesToSummaries < ActiveRecord::Migration[6.1]
  def change
    add_column :summaries, :keyword, :string
    add_column :summaries, :difficulty_id, :integer
    add_column :summaries, :length_id, :integer
  end
end