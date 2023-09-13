class CreateLengths < ActiveRecord::Migration[6.1]
  def change
    create_table :lengths do |t|
      t.string :length
    end
  end
end