class CreatePacientes < ActiveRecord::Migration[8.1]
  def change
    create_table :pacientes do |t|
      t.string :nome

      t.timestamps
    end
  end
end
