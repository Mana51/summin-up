class AddTitlesToSummaries < ActiveRecord::Migration[6.1]
  def change
      add_column :summaries, :title, :string
  end
end
