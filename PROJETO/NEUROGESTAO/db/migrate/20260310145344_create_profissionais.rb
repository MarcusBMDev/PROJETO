class CreateProfissionais < ActiveRecord::Migration[8.1]
  def change
    create_table :profissionais do |t|
      t.string :nome
      t.string :especialidade

      t.timestamps
    end
  end
end
