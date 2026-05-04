class CreateConvenios < ActiveRecord::Migration[8.1]
  def change
    create_table :convenios do |t|
      t.string :nome

      t.timestamps
    end
  end
end
