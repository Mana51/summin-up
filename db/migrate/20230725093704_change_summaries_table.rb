class ChangeSummariesTable < ActiveRecord::Migration[6.1]
  def change
    remove_column :summaries, :content, :string
    remove_column :summaries, :keyword, :integer
    remove_column :summaries, :difficulty_id, :integer
    remove_column :summaries, :length_id, :integer
    add_column :summaries, :user_id, :integer
    add_column :summaries, :summary, :string
  end
end
