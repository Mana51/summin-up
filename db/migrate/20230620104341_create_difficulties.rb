class CreateDifficulties < ActiveRecord::Migration[6.1]
  def change
    create_table :difficulties do |t|
      t.string:difficulty

    end
  end
end
